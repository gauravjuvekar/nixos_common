use crate::modules::calendar::Timezones;
use crate::modules::{self, Refreshable};
use crate::refresh::Refresh;
use serde_json::{Value, json};
use std::io::{self, Write};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

struct Module<'a> {
    source: Box<dyn Refreshable + 'a>,
    refreshed: Option<Instant>,
    last_error: Option<String>,
}

impl<'a> Module<'a> {
    fn new(source: Box<dyn Refreshable + 'a>) -> Self {
        Self {
            source,
            refreshed: None,
            last_error: None,
        }
    }

    fn refresh(&mut self, data: &mut Value, force: bool) {
        if !force
            && self
                .refreshed
                .is_some_and(|time| time.elapsed() < self.source.interval())
        {
            return;
        }
        match self.source.refresh(data) {
            Ok(()) => self.last_error = None,
            Err(error) => {
                let error = error.to_string();
                if self.last_error.as_ref() != Some(&error) {
                    eprintln!("bar-status: {error}");
                    self.last_error = Some(error);
                }
            }
        }
        self.refreshed = Some(Instant::now());
    }
}

struct Output<W> {
    data: Value,
    writer: W,
}

impl<W: Write> Output<W> {
    fn new(writer: W) -> Self {
        Self {
            data: json!({"workspaces": [], "windows": [], "titles": []}),
            writer,
        }
    }

    fn publish(&mut self, patch: &Value) -> io::Result<()> {
        for (key, value) in patch.as_object().unwrap() {
            self.data[key] = value.clone();
        }
        // Eww needs a complete status object, including the first periodic sample.
        if self.data.get("clock").is_some() {
            writeln!(self.writer, "{}", self.data)?;
            self.writer.flush()?;
        }
        Ok(())
    }
}

pub fn watch(once: bool, zones: &Timezones) -> io::Result<()> {
    let refresh = if once { None } else { Some(Refresh::listen()?) };
    let output = Arc::new(Mutex::new(Output::new(io::stdout())));
    if !once {
        let output = output.clone();
        thread::spawn(move || {
            let _ =
                modules::desktop::Desktop::watch(|patch| output.lock().unwrap().publish(&patch));
        });
    }
    let mut modules: Vec<_> = modules::periodic(zones)
        .into_iter()
        .map(Module::new)
        .collect();
    let mut data = json!({});
    if once {
        Module::new(Box::new(modules::desktop::Desktop::new())).refresh(&mut data, false);
    }
    let mut force = false;
    loop {
        let start = Instant::now();
        for module in &mut modules {
            module.refresh(&mut data, force);
        }
        // No output lock is held while status commands run. The event thread can
        // publish focus/workspace changes immediately, even during a slow refresh.
        output.lock().unwrap().publish(&data)?;
        if once {
            return Ok(());
        }
        force = refresh
            .as_ref()
            .unwrap()
            .wait(Duration::from_secs(1).saturating_sub(start.elapsed()));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::Cell;
    use std::rc::Rc;

    #[test]
    fn event_updates_are_published_separately_and_periodic_samples_cannot_undo_them() {
        let mut output = Output::new(Vec::new());
        output
            .publish(&json!({"windows": [{"id": 8, "state": "active"}]}))
            .unwrap();
        // Wait for the first complete periodic sample before emitting status.
        assert!(output.writer.is_empty());
        output
            .publish(&json!({"clock": {"text": "now"}, "bluetooth": {"state": "off"}}))
            .unwrap();
        output.publish(&json!({"windows": [{"id": 9, "state": "active"}], "workspaces": [{"id": 18, "state": "active"}]})).unwrap();
        output
            .publish(&json!({"clock": {"text": "later"}, "bluetooth": {"state": "off"}}))
            .unwrap();
        let snapshots: Vec<Value> = String::from_utf8(output.writer)
            .unwrap()
            .lines()
            .map(|line| serde_json::from_str(line).unwrap())
            .collect();
        assert_eq!(snapshots.len(), 3);
        assert_eq!(snapshots[1]["windows"][0]["id"], 9);
        assert_eq!(snapshots[1]["workspaces"][0]["id"], 18);
        assert_eq!(snapshots[1]["clock"]["text"], "now");
        assert_eq!(snapshots[2]["windows"], snapshots[1]["windows"]);
        assert_eq!(snapshots[2]["workspaces"], snapshots[1]["workspaces"]);
        assert_eq!(snapshots[2]["clock"]["text"], "later");
    }

    struct Counter {
        calls: Rc<Cell<u32>>,
        fail: Rc<Cell<bool>>,
        interval: Duration,
    }

    impl Refreshable for Counter {
        fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
            self.calls.set(self.calls.get() + 1);
            if self.fail.get() {
                return Err(io::Error::other("unavailable"));
            }
            data["counter"] = json!(self.calls.get());
            Ok(())
        }

        fn interval(&self) -> Duration {
            self.interval
        }
    }

    fn counter(interval: Duration) -> (Module<'static>, Rc<Cell<u32>>, Rc<Cell<bool>>) {
        let calls = Rc::new(Cell::new(0));
        let fail = Rc::new(Cell::new(false));
        let module = Module::new(Box::new(Counter {
            calls: calls.clone(),
            fail: fail.clone(),
            interval,
        }));
        (module, calls, fail)
    }

    #[test]
    fn slow_modules_refresh_initially_on_expiry_and_when_forced() {
        let interval = Duration::from_secs(10);
        let (mut module, calls, _) = counter(interval);
        let mut data = json!({});
        module.refresh(&mut data, false);
        assert_eq!(calls.get(), 1);
        module.refresh(&mut data, false);
        assert_eq!(calls.get(), 1);
        assert_eq!(data["counter"], 1);
        module.refreshed = Some(Instant::now() - interval);
        module.refresh(&mut data, false);
        assert_eq!(calls.get(), 2);
        module.refresh(&mut data, true);
        assert_eq!(calls.get(), 3);
        assert_eq!(data["counter"], 3);
    }

    #[test]
    fn fast_modules_refresh_every_cycle_and_recover_after_errors() {
        let (mut module, calls, fail) = counter(Duration::ZERO);
        let mut data = json!({});
        module.refresh(&mut data, false);
        module.refresh(&mut data, false);
        assert_eq!(calls.get(), 2);
        fail.set(true);
        module.refresh(&mut data, false);
        assert_eq!(data["counter"], 2);
        assert_eq!(module.last_error.as_deref(), Some("unavailable"));
        module.refresh(&mut data, false);
        assert_eq!(data["counter"], 2);
        fail.set(false);
        module.refresh(&mut data, false);
        assert_eq!(data["counter"], 5);
        assert!(module.last_error.is_none());
    }
}

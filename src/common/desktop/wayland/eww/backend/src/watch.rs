use crate::command;
use crate::modules::calendar::Timezones;
use crate::modules::{self, Refreshable};
use crate::refresh::Refresh;
use serde_json::{Value, json};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
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

struct Output<W, F> {
    data: Value,
    writer: W,
    update: F,
}

impl<W: Write, F: FnMut(&Value) -> io::Result<()>> Output<W, F> {
    fn new(writer: W, update: F) -> Self {
        Self {
            data: json!({}),
            writer,
            update,
        }
    }

    fn publish(&mut self, patch: &Value) -> io::Result<()> {
        let mut changed = json!({});
        for (key, value) in patch.as_object().unwrap() {
            if key != "timezone_times" && self.data.get(key) != Some(value) {
                changed[key] = value.clone();
            }
        }
        if !changed.as_object().unwrap().is_empty() {
            (self.update)(&changed)?;
        }
        if let Some(texts) = patch.get("timezone_times") {
            if self.data.get("timezone_times") != Some(texts) {
                writeln!(self.writer, "{texts}")?;
                self.writer.flush()?;
            }
        }
        for (key, value) in patch.as_object().unwrap() {
            self.data[key] = value.clone();
        }
        Ok(())
    }
}

fn update_eww(changed: &Value, config: Option<&Path>) -> io::Result<()> {
    let mut args = Vec::new();
    if let Some(config) = config {
        args.extend(["--config".into(), config.to_string_lossy().into_owned()]);
    }
    args.push("update".to_string());
    args.extend(
        changed
            .as_object()
            .unwrap()
            .iter()
            .map(|(key, value)| format!("{key}={value}")),
    );
    command::run("eww", &args.iter().map(String::as_str).collect::<Vec<_>>())
        .ok_or_else(|| io::Error::other("Could not update Eww variables"))?;
    Ok(())
}

pub fn watch(once: bool, zones: &Timezones, eww_config: Option<PathBuf>) -> io::Result<()> {
    let refresh = if once { None } else { Some(Refresh::listen()?) };
    let output = Arc::new(Mutex::new(Output::new(
        io::stdout(),
        move |changed: &Value| update_eww(changed, eww_config.as_deref()),
    )));
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
        if once {
            println!("{data}");
            return Ok(());
        }
        output.lock().unwrap().publish(&data)?;
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
    fn clock_ticks_publish_only_time_fields_and_preserve_desktop_events() {
        let mut updates = Vec::new();
        let mut output = Output::new(Vec::new(), |changed: &Value| {
            updates.push(changed.clone());
            Ok(())
        });
        let sample = json!({
            "timezone_times": {"UTC": "now"},
            "calendar_texts": {"": "2026"}, "timezone_names": ["UTC"],
            "clock_selections": {"": "UTC"}, "bluetooth": {"state": "off"}
        });
        output.publish(&sample).unwrap();
        output.publish(&sample).unwrap();
        output.publish(&json!({"windows": [{"id": 9}]})).unwrap();
        let mut tick = sample.clone();
        tick["timezone_times"]["UTC"] = json!("later");
        output.publish(&tick).unwrap();
        assert_eq!(output.data["windows"][0]["id"], 9);
        let lines: Vec<Value> = String::from_utf8(output.writer)
            .unwrap()
            .lines()
            .map(|line| serde_json::from_str(line).unwrap())
            .collect();
        assert_eq!(lines, [json!({"UTC": "now"}), json!({"UTC": "later"})]);
        assert_eq!(updates.len(), 2);
        assert_eq!(updates[1], json!({"windows": [{"id": 9}]}));
    }

    #[test]
    fn failed_delivery_is_retried_without_forgetting_the_previous_values() {
        let mut fail = true;
        let mut output = Output::new(Vec::new(), |_: &Value| {
            if std::mem::take(&mut fail) {
                Err(io::Error::other("disconnected"))
            } else {
                Ok(())
            }
        });
        let patch = json!({"volume": {"percentage": "50%"}});
        assert!(output.publish(&patch).is_err());
        assert!(output.data.get("volume").is_none());
        output.publish(&patch).unwrap();
        assert_eq!(output.data, patch);
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

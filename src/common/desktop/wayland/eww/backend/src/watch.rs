use crate::command;
use crate::modules::calendar::Timezones;
use crate::modules::{self, Refreshable, Target};
use crate::refresh::Refresh;
use serde_json::{Value, json};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;
use std::time::Instant;

struct Module {
    source: Box<dyn Refreshable>,
    last_error: Option<String>,
}

impl Module {
    fn new(source: Box<dyn Refreshable>) -> Self {
        Self {
            source,
            last_error: None,
        }
    }

    fn refresh(&mut self, data: &mut Value) {
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
        if let Some(texts) = patch.get("timezone_times")
            && self.data.get("timezone_times") != Some(texts)
        {
            writeln!(self.writer, "{texts}")?;
            self.writer.flush()?;
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

fn run_module(source: Box<dyn Refreshable>, wake: Receiver<()>, patches: Sender<Value>) {
    let mut module = Module::new(source);
    let mut data = json!({});
    loop {
        let start = Instant::now();
        module.refresh(&mut data);
        if patches.send(data.clone()).is_err() {
            return;
        }
        match wake.recv_timeout(module.source.interval().saturating_sub(start.elapsed())) {
            Ok(()) => {
                // One refresh covers clicks queued while a status command was running.
                while wake.try_recv().is_ok() {}
            }
            Err(mpsc::RecvTimeoutError::Timeout) => (),
            Err(mpsc::RecvTimeoutError::Disconnected) => return,
        }
    }
}

fn route(target: Target, controls: &[(Target, Sender<()>)]) {
    for (id, wake) in controls {
        if *id == target {
            let _ = wake.send(());
        }
    }
}

pub fn watch(once: bool, zones: &Timezones, eww_config: Option<PathBuf>) -> io::Result<()> {
    if once {
        let mut data = json!({});
        Module::new(Box::new(modules::desktop::Desktop::new())).refresh(&mut data);
        for (_, source) in modules::periodic(zones) {
            Module::new(source).refresh(&mut data);
        }
        println!("{data}");
        return Ok(());
    }

    let refresh = Refresh::listen()?;
    let (send, patches) = mpsc::channel();
    let mut controls = Vec::new();
    for (target, source) in modules::periodic(zones) {
        let (wake, wait) = mpsc::channel();
        controls.push((target, wake));
        let send = send.clone();
        thread::spawn(move || run_module(source, wait, send));
    }
    thread::spawn(move || {
        loop {
            match refresh.receive() {
                Ok(Some(target)) => route(target, &controls),
                Ok(None) => (),
                Err(error) => {
                    eprintln!("bar-status: refresh socket: {error}");
                    return;
                }
            }
        }
    });
    thread::spawn(move || {
        let _ = modules::desktop::Desktop::watch(|patch| {
            send.send(patch)
                .map_err(|_| io::Error::new(io::ErrorKind::BrokenPipe, "Publisher stopped"))
        });
    });
    let mut output = Output::new(io::stdout(), move |changed: &Value| {
        update_eww(changed, eww_config.as_deref())
    });
    for patch in patches {
        output.publish(&patch)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

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
        key: &'static str,
        calls: u32,
        fail: bool,
        interval: Duration,
    }

    impl Refreshable for Counter {
        fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
            self.calls += 1;
            if self.fail {
                return Err(io::Error::other("unavailable"));
            }
            data[self.key] = json!(self.calls);
            Ok(())
        }

        fn interval(&self) -> Duration {
            self.interval
        }
    }

    fn counter(key: &'static str) -> Counter {
        Counter {
            key,
            calls: 0,
            fail: false,
            interval: Duration::from_secs(60),
        }
    }

    #[test]
    fn source_errors_preserve_the_last_sample_and_recover() {
        let mut module = Module::new(Box::new(counter("counter")));
        let mut data = json!({});
        module.refresh(&mut data);
        assert_eq!(data["counter"], 1);
        module.source = Box::new(Counter {
            fail: true,
            ..counter("counter")
        });
        module.refresh(&mut data);
        assert_eq!(data["counter"], 1);
        assert_eq!(module.last_error.as_deref(), Some("unavailable"));
        module.source = Box::new(counter("counter"));
        module.refresh(&mut data);
        assert!(module.last_error.is_none());
    }

    #[test]
    fn actions_wake_only_the_target_worker() {
        let (send, patches) = mpsc::channel();
        let mut controls = Vec::new();
        let mut workers = Vec::new();
        for (target, key) in [(Target::Clock, "clock"), (Target::Bluetooth, "bluetooth")] {
            let (wake, wait) = mpsc::channel();
            controls.push((target, wake));
            let send = send.clone();
            workers.push(thread::spawn(move || {
                run_module(Box::new(counter(key)), wait, send)
            }));
        }
        for _ in 0..2 {
            patches.recv_timeout(Duration::from_secs(2)).unwrap();
        }
        route(Target::Clock, &controls);
        assert_eq!(
            patches.recv_timeout(Duration::from_secs(2)).unwrap(),
            json!({"clock": 2})
        );
        route(Target::Bluetooth, &controls);
        assert_eq!(
            patches.recv_timeout(Duration::from_secs(2)).unwrap(),
            json!({"bluetooth": 2})
        );
        drop(controls);
        for worker in workers {
            worker.join().unwrap();
        }
        assert!(patches.try_recv().is_err());
    }

    struct Blocked(Receiver<()>);

    impl Refreshable for Blocked {
        fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
            self.0.recv().unwrap();
            data["slow"] = json!(true);
            Ok(())
        }
        fn interval(&self) -> Duration {
            Duration::from_secs(60)
        }
    }

    #[test]
    fn a_blocked_probe_does_not_delay_other_sources_or_their_deadlines() {
        let (send, patches) = mpsc::channel();
        let (release, block) = mpsc::channel();
        let (slow_wake, slow_wait) = mpsc::channel();
        let slow_send = send.clone();
        let slow =
            thread::spawn(move || run_module(Box::new(Blocked(block)), slow_wait, slow_send));
        let (fast_wake, fast_wait) = mpsc::channel();
        let fast = thread::spawn(move || {
            run_module(
                Box::new(Counter {
                    interval: Duration::from_millis(10),
                    ..counter("fast")
                }),
                fast_wait,
                send,
            )
        });
        for count in 1..=2 {
            assert_eq!(
                patches.recv_timeout(Duration::from_secs(2)).unwrap(),
                json!({"fast": count})
            );
        }
        drop(fast_wake);
        fast.join().unwrap();
        assert!(patches.try_iter().all(|patch| patch.get("fast").is_some()));
        drop(slow_wake);
        release.send(()).unwrap();
        slow.join().unwrap();
        assert_eq!(
            patches.recv_timeout(Duration::from_secs(2)).unwrap(),
            json!({"slow": true})
        );
    }
}

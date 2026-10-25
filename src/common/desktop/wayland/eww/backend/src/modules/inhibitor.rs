use super::Refreshable;
use crate::command::run;
use serde_json::{Value, json};
use std::io;

pub struct Inhibitor;

impl Refreshable for Inhibitor {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        data["inhibited"] = json!(inhibited());
        Ok(())
    }
}

fn inhibited() -> bool {
    run(
        "systemctl",
        &["--user", "is-active", "eww-idle-inhibitor.service"],
    )
    .as_deref()
        == Some("active")
}

pub fn toggle_inhibitor() -> Result<(), String> {
    run(
        "systemctl",
        &[
            "--user",
            if inhibited() { "stop" } else { "start" },
            "eww-idle-inhibitor.service",
        ],
    )
    .map(|_| ())
    .ok_or_else(|| "Could not toggle idle inhibition".into())
}

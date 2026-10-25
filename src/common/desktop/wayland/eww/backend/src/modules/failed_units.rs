use super::Refreshable;
use crate::command::run;
use serde_json::{Value, json};
use std::io;
use std::time::Duration;

pub struct FailedUnits;

impl Refreshable for FailedUnits {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        data["failed"] = failed_units();
        Ok(())
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(10)
    }
}

fn failed_units() -> Value {
    let system = run(
        "systemctl",
        &["--system", "show", "--property=NFailedUnits", "--value"],
    );
    let user = run(
        "systemctl",
        &["--user", "show", "--property=NFailedUnits", "--value"],
    );
    failed_view(system.as_deref(), user.as_deref())
}

fn failed_view(system: Option<&str>, user: Option<&str>) -> Value {
    let counts = [system, user].map(|count| count.and_then(|count| count.parse::<u32>().ok()));
    let healthy = counts == [Some(0), Some(0)];
    let unknown = counts.iter().any(Option::is_none);
    json!({"text":format!("{}/{}", system.unwrap_or("?"), user.unwrap_or("?")),
        "state":if healthy { "normal" } else { "degraded" }, "visible":!healthy,
        "tooltip":if unknown { "Unable to query system/user failed units" } else { "Failed system/user units" }})
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn healthy_units_are_hidden_but_query_failures_are_visible() {
        assert_eq!(failed_view(Some("0"), Some("0"))["visible"], false);
        assert_eq!(failed_view(None, Some("0"))["visible"], true);
        assert_eq!(failed_view(Some("1"), Some("0"))["state"], "degraded");
    }
}

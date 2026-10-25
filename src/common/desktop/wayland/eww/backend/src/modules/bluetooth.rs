use super::Refreshable;
use crate::command::run;
use serde_json::{Value, json};
use std::io;
use std::time::Duration;

pub struct Bluetooth;

impl Refreshable for Bluetooth {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        data["bluetooth"] = bluetooth();
        Ok(())
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(10)
    }
}

fn bluetooth() -> Value {
    let adapter = run("bluetoothctl", &["show"]);
    let devices = adapter
        .as_ref()
        .filter(|value| value.contains("Powered: yes"))
        .and_then(|_| run("bluetoothctl", &["devices", "Connected"]));
    bluetooth_view(adapter.as_deref(), devices.as_deref())
}

fn bluetooth_view(adapter: Option<&str>, devices: Option<&str>) -> Value {
    let Some(adapter) = adapter.filter(|text| text.contains("Controller ")) else {
        return json!({"text":"off", "state":"no-controller", "tooltip":"No Bluetooth controller"});
    };
    let powered = adapter.contains("Powered: yes");
    let count = devices
        .map(|text| {
            text.lines()
                .filter(|line| line.starts_with("Device "))
                .count()
        })
        .unwrap_or(0);
    let state = if !powered {
        "off"
    } else if adapter.contains("Discovering: yes") {
        "discovering"
    } else if adapter.contains("Discoverable: yes") {
        "discoverable"
    } else {
        "on"
    };
    let text = if !powered {
        "off".to_string()
    } else if count > 0 {
        format!("{count} con")
    } else {
        "on".to_string()
    };
    let alias = adapter
        .lines()
        .find_map(|line| line.trim().strip_prefix("Alias: "))
        .unwrap_or("Bluetooth");
    let address = adapter
        .lines()
        .find_map(|line| line.trim().strip_prefix("Controller "))
        .and_then(|line| line.split_whitespace().next())
        .unwrap_or("");
    let connected = devices
        .unwrap_or("")
        .lines()
        .map(|line| line.trim_start_matches("Device "))
        .collect::<Vec<_>>()
        .join("\n");
    json!({"text":text, "state":state, "tooltip":format!("{alias}  {address}\n\n{connected}").trim()})
}

pub fn toggle_bluetooth() -> Result<(), String> {
    let adapter = run("bluetoothctl", &["show"]).ok_or("Could not query Bluetooth")?;
    run(
        "bluetoothctl",
        &[
            "power",
            if adapter.contains("Powered: yes") {
                "off"
            } else {
                "on"
            },
        ],
    )
    .map(|_| ())
    .ok_or_else(|| "Could not toggle Bluetooth".into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bluetooth_status_and_device_counts_are_distinct() {
        let adapter = "Controller AA:BB test\n Alias: Laptop\n Powered: yes\n Discovering: no\n Discoverable: no";
        assert_eq!(bluetooth_view(Some(adapter), Some(""))["text"], "on");
        assert_eq!(
            bluetooth_view(Some(adapter), Some("Device 11 A\nDevice 22 B"))["text"],
            "2 con"
        );
        assert_eq!(bluetooth_view(None, None)["state"], "no-controller");
    }
}

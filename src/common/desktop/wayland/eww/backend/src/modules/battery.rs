use super::{Refreshable, sysfs::read};
use serde_json::{Value, json};
use std::io;
use std::path::Path;

pub struct Battery;

impl Refreshable for Battery {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        data["battery"] = battery();
        Ok(())
    }
}

fn battery() -> Value {
    let root = Path::new("/sys/class/power_supply/BAT0");
    battery_view(&read(root.join("capacity")), &read(root.join("status")))
}

fn battery_view(capacity: &str, status: &str) -> Value {
    let Ok(capacity) = capacity.parse::<u32>() else {
        return json!({"text":"?%", "icon":"battery-empty", "state":"unknown", "tooltip":"Battery unavailable"});
    };
    let charging = matches!(status, "Charging" | "Full" | "Not charging");
    let state = if charging {
        "charging"
    } else if capacity <= 10 {
        "critical"
    } else if capacity <= 25 {
        "warning"
    } else {
        "normal"
    };
    let icon = match capacity {
        0..=10 => "battery-empty",
        11..=35 => "battery-low",
        36..=60 => "battery-half",
        61..=85 => "battery-high",
        _ => "battery-full",
    };
    json!({"text":format!("{capacity}%"), "icon":icon, "state":state, "tooltip":format!("BAT0: {capacity}% ({status})")})
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn battery_states_keep_charging_out_of_critical_animation() {
        assert_eq!(battery_view("9", "Discharging")["state"], "critical");
        assert_eq!(battery_view("9", "Charging")["state"], "charging");
        assert_eq!(battery_view("96", "Discharging")["text"], "96%");
        assert_eq!(battery_view("96", "Discharging")["icon"], "battery-full");
        assert_eq!(battery_view("?", "")["state"], "unknown");
    }
}

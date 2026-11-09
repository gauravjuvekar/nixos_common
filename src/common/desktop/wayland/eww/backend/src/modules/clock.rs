use super::Refreshable;
use super::calendar::{self, State, Timezones};
use serde_json::{Value, json};
use std::io;

pub struct Clock<'a> {
    zones: &'a Timezones,
}

impl<'a> Clock<'a> {
    pub fn new(zones: &'a Timezones) -> Self {
        Self { zones }
    }
}

impl Refreshable for Clock<'_> {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        let now = chrono::Utc::now();
        for (key, value) in view(now, State::load_all(), self.zones)
            .as_object()
            .unwrap()
        {
            data[key] = value.clone();
        }
        Ok(())
    }
}

fn view(
    now: chrono::DateTime<chrono::Utc>,
    mut states: std::collections::BTreeMap<String, State>,
    zones: &Timezones,
) -> Value {
    // Output names come from Niri. The empty name supplies defaults for new bars.
    states.insert(String::new(), State::default());
    let mut data = json!({
        "calendar_texts": {}, "clock_selections": {},
        "timezone_names": [], "timezone_times": {},
    });
    for (output, state) in states {
        let clock = calendar::clock(now, &state, zones);
        let key = output.as_str();
        data["calendar_texts"][key] = json!(clock.calendar);
        data["clock_selections"][key] = json!(
            clock
                .timezones
                .iter()
                .find(|zone| zone.selected)
                .unwrap()
                .name
        );
        if output.is_empty() {
            data["timezone_names"] = json!(
                clock
                    .timezones
                    .iter()
                    .map(|zone| zone.name)
                    .collect::<Vec<_>>()
            );
            for zone in clock.timezones {
                data["timezone_times"][zone.name] = json!(zone.time);
            }
        }
    }
    data
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{TimeZone, Utc};
    use std::collections::BTreeMap;

    #[test]
    fn second_ticks_leave_calendar_selection_and_row_order_unchanged() {
        let zones = serde_json::from_str(r#"["Etc/UTC", "America/Los_Angeles"]"#).unwrap();
        let now = Utc.with_ymd_and_hms(2026, 11, 9, 12, 0, 0).unwrap();
        let before = view(now, BTreeMap::new(), &zones);
        let after = view(now + chrono::Duration::seconds(1), BTreeMap::new(), &zones);
        for key in ["calendar_texts", "clock_selections", "timezone_names"] {
            assert_eq!(before[key], after[key], "{key}");
        }
        assert_ne!(before["timezone_times"], after["timezone_times"]);
    }

    #[test]
    fn timezone_changes_update_only_the_selected_output_and_its_calendar() {
        let zones: Timezones =
            serde_json::from_str(r#"["Etc/UTC", "America/Los_Angeles"]"#).unwrap();
        let now = Utc.with_ymd_and_hms(2027, 1, 1, 0, 30, 0).unwrap();
        let mut states = BTreeMap::new();
        states.insert(
            "DP-1".into(),
            State {
                timezone: 1,
                ..State::default()
            },
        );
        states.insert("DP-2".into(), State::default());
        let result = view(now, states, &zones);
        assert_eq!(result["clock_selections"]["DP-1"], "America/Los_Angeles");
        assert_eq!(result["clock_selections"]["DP-2"], "Etc/UTC");
        assert_eq!(
            result["clock_selections"]["DP-2"],
            result["clock_selections"][""]
        );
        assert!(
            result["calendar_texts"]["DP-1"]
                .as_str()
                .unwrap()
                .contains("2026")
        );
        assert!(
            result["calendar_texts"]["DP-2"]
                .as_str()
                .unwrap()
                .contains("2027")
        );
    }
}

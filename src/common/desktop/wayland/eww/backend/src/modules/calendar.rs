use chrono::{DateTime, Datelike, Duration, NaiveDate, Utc};
use chrono_tz::Tz;
use serde::{Deserialize, Serialize};
use std::fs::{self, File, OpenOptions};
use std::io;
use std::path::PathBuf;

#[derive(Deserialize)]
#[serde(try_from = "Vec<String>")]
pub struct Timezones(Vec<Tz>);

impl Timezones {
    pub fn index(&self, name: &str) -> io::Result<usize> {
        self.0
            .iter()
            .position(|zone| zone.name() == name)
            .ok_or_else(|| io::Error::other(format!("Timezone is not configured: {name}")))
    }

    #[cfg(test)]
    fn parse(value: &str) -> io::Result<Self> {
        serde_json::from_str(value).map_err(io::Error::other)
    }
}

impl TryFrom<Vec<String>> for Timezones {
    type Error = String;

    fn try_from(names: Vec<String>) -> Result<Self, Self::Error> {
        if names.is_empty() {
            return Err("timezones must contain at least one timezone".into());
        }
        names
            .into_iter()
            .map(|name| {
                name.parse::<Tz>()
                    .map_err(|_| format!("Unknown timezone: {name}"))
            })
            .collect::<Result<Vec<_>, _>>()
            .map(Self)
    }
}

#[derive(Default, Deserialize, Serialize)]
#[serde(default)]
pub struct State {
    pub timezone: usize,
    pub calendar_offset: i32,
    pub month_view: bool,
}

fn state_path() -> io::Result<PathBuf> {
    xdg::BaseDirectories::new().get_runtime_file("eww-clock.json")
}

impl State {
    pub fn load() -> Self {
        state_path()
            .ok()
            .and_then(|path| fs::read(path).ok())
            .and_then(|bytes| serde_json::from_slice(&bytes).ok())
            .unwrap_or_default()
    }

    pub fn update(update: impl FnOnce(&mut Self)) -> io::Result<()> {
        let path = state_path()?;
        let lock = OpenOptions::new()
            .create(true)
            .truncate(false)
            .write(true)
            .open(path.with_extension("lock"))?;
        File::lock(&lock)?;
        let mut state = Self::load();
        update(&mut state);
        let temporary = path.with_extension("tmp");
        fs::write(&temporary, serde_json::to_vec(&state)?)?;
        fs::rename(temporary, path)
    }

    pub fn shift_timezone(&mut self, step: i32, zones: &Timezones) {
        let current = (self.timezone % zones.0.len()) as i64;
        self.timezone = (current + i64::from(step)).rem_euclid(zones.0.len() as i64) as usize;
    }
}

#[derive(Serialize)]
pub struct ZoneLine {
    pub name: &'static str,
    pub time: String,
    pub selected: bool,
}

#[derive(Serialize)]
pub struct Clock {
    pub text: String,
    pub timezones: Vec<ZoneLine>,
    pub calendar: String,
}

pub fn clock(now: DateTime<Utc>, state: &State, zones: &Timezones) -> Clock {
    let selected_index = state.timezone % zones.0.len();
    let selected = zones.0[selected_index];
    let local = now.with_timezone(&selected);
    let timezones = zones
        .0
        .iter()
        .enumerate()
        .map(|(index, zone)| ZoneLine {
            name: zone.name(),
            time: now.with_timezone(zone).format("%a %F %T%z %Z").to_string(),
            selected: index == selected_index,
        })
        .collect();
    let calendar = if state.month_view {
        let month = local.year() * 12 + local.month0() as i32 + state.calendar_offset;
        month_lines(month.div_euclid(12), month.rem_euclid(12) as u32 + 1).join("\n")
    } else {
        year_calendar((local.year() + state.calendar_offset).clamp(1, 9999))
    };
    Clock {
        text: local.format("%a %F %T%z %Z").to_string(),
        timezones,
        calendar,
    }
}

// ISO week numbers stay to the left; fixed-width rows preserve all three columns.
fn month_lines(year: i32, month: u32) -> Vec<String> {
    let first = NaiveDate::from_ymd_opt(year, month, 1).unwrap();
    let start = first - Duration::days(first.weekday().num_days_from_monday() as i64);
    let mut lines = vec![
        format!("{:^23}", first.format("%B %Y").to_string()),
        "Wk Mo Tu We Th Fr Sa Su".to_string(),
    ];
    for week in 0..6 {
        let monday = start + Duration::days(week * 7);
        let mut row = format!("{:02}", monday.iso_week().week());
        let mut has_day = false;
        for day in 0..7 {
            let date = monday + Duration::days(day);
            if date.month() == month && date.year() == year {
                row.push_str(&format!(" {:2}", date.day()));
                has_day = true;
            } else {
                row.push_str("   ");
            }
        }
        lines.push(if has_day { row } else { " ".repeat(23) });
    }
    lines
}

pub fn year_calendar(year: i32) -> String {
    let mut lines = vec![format!("{year:^73}"), String::new()];
    for first_month in [1, 4, 7, 10] {
        let months: Vec<_> = (first_month..first_month + 3)
            .map(|month| month_lines(year, month))
            .collect();
        for row in 0..8 {
            lines.push(
                months
                    .iter()
                    .map(|month| month[row].as_str())
                    .collect::<Vec<_>>()
                    .join("  "),
            );
        }
        lines.push(String::new());
    }
    lines.join("\n")
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    #[test]
    fn timezone_rows_share_a_timestamp_and_handle_day_rollover() {
        let now = Utc.with_ymd_and_hms(2026, 10, 25, 2, 30, 0).unwrap();
        let zones = Timezones::parse(r#"["America/Los_Angeles", "Asia/Kolkata"]"#).unwrap();
        let clock = clock(now, &State::default(), &zones);
        assert_eq!(clock.timezones[0].time, "Sat 2026-10-24 19:30:00-0700 PDT");
        assert_eq!(clock.timezones[1].time, "Sun 2026-10-25 08:00:00+0530 IST");
        assert!(clock.timezones.iter().all(|zone| zone.time.len() == 32));
    }

    #[test]
    fn fixed_columns_and_iso_weeks_survive_leap_years() {
        for year in [2024, 2025, 2026, 2028] {
            let calendar = year_calendar(year);
            assert!(
                calendar
                    .lines()
                    .all(|line| line.is_empty() || line.len() == 73)
            );
            assert_eq!(calendar.matches("Wk Mo Tu We Th Fr Sa Su").count(), 12);
        }
        assert!(month_lines(2024, 2).iter().any(|line| line.contains("29")));
        assert!(month_lines(2026, 1)[2].starts_with("01"));
    }

    #[test]
    fn timezone_cycle_wraps_and_keeps_calendar_state() {
        let zones = Timezones::parse(r#"["Asia/Taipei", "Etc/UTC", "Europe/London"]"#).unwrap();
        let mut state = State {
            calendar_offset: 2,
            ..State::default()
        };
        state.shift_timezone(-1, &zones);
        assert_eq!(state.timezone, 2);
        state.shift_timezone(1, &zones);
        assert_eq!(state.timezone, 0);
        assert_eq!(state.calendar_offset, 2);
    }

    #[test]
    fn timezone_selection_updates_clock_and_calendar_across_year_boundary() {
        let now = Utc.with_ymd_and_hms(2027, 1, 1, 0, 30, 0).unwrap();
        let zones = Timezones::parse(r#"["Etc/UTC", "America/Los_Angeles"]"#).unwrap();
        let mut state = State {
            month_view: true,
            calendar_offset: 1,
            ..State::default()
        };
        let before = clock(now, &state, &zones);
        assert!(before.calendar.contains("February 2027"));
        assert!(before.timezones[0].selected);

        state.timezone = zones.index("America/Los_Angeles").unwrap();
        let after = clock(now, &state, &zones);
        assert_eq!(after.text, "Thu 2026-12-31 16:30:00-0800 PST");
        assert_eq!(after.text, after.timezones[1].time);
        assert!(!after.timezones[0].selected);
        assert!(after.timezones[1].selected);
        assert!(after.calendar.contains("January 2027"));
        assert!(state.month_view);
        assert_eq!(state.calendar_offset, 1);

        assert!(zones.index("Asia/Taipei").is_err());
        assert!(zones.index("Invalid/Zone").is_err());
    }

    #[test]
    fn configured_order_controls_rows_and_default_zone() {
        let now = Utc.with_ymd_and_hms(2026, 10, 25, 2, 30, 0).unwrap();
        let zones = Timezones::parse(r#"["Asia/Taipei", "Etc/UTC", "Asia/Kolkata"]"#).unwrap();
        let mut state = State::default();
        let view = clock(now, &state, &zones);
        assert_eq!(
            view.timezones
                .iter()
                .map(|row| row.name)
                .collect::<Vec<_>>(),
            ["Asia/Taipei", "Etc/UTC", "Asia/Kolkata"]
        );
        assert_eq!(view.text, view.timezones[0].time);
        state.timezone = 17; // A previous configuration may have had more zones.
        assert_eq!(clock(now, &state, &zones).text, view.timezones[2].time);
        state.shift_timezone(1, &zones);
        assert_eq!(state.timezone, 0);
    }

    #[test]
    fn empty_invalid_and_single_zone_configurations() {
        assert!(Timezones::parse("[]").is_err());
        assert!(Timezones::parse(r#"["Invalid/Zone"]"#).is_err());
        assert!(Timezones::parse(r#""Etc/UTC""#).is_err());
        let zones = Timezones::parse(r#"["Etc/UTC"]"#).unwrap();
        let mut state = State::default();
        state.shift_timezone(-1, &zones);
        assert_eq!(state.timezone, 0);
        state.shift_timezone(1, &zones);
        assert_eq!(state.timezone, 0);
    }
}

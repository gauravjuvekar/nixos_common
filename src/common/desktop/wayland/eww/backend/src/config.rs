use crate::modules::calendar::Timezones;
use serde::Deserialize;
use std::fs;
use std::io;
use std::path::Path;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    pub timezones: Timezones,
}

impl Config {
    pub fn load(path: &Path) -> io::Result<Self> {
        let text = fs::read_to_string(path).map_err(|error| {
            io::Error::other(format!("Cannot read {}: {error}", path.display()))
        })?;
        serde_json::from_str(&text).map_err(|error| {
            io::Error::other(format!("Invalid config {}: {error}", path.display()))
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::modules::calendar::{State, clock};

    #[test]
    fn file_configuration_preserves_timezone_order() {
        let path =
            std::env::temp_dir().join(format!("bar-status-config-{}.json", std::process::id()));
        fs::write(&path, r#"{"timezones":["Etc/UTC","Asia/Taipei"]}"#).unwrap();
        let config = Config::load(&path).unwrap();
        let view = clock(chrono::Utc::now(), &State::default(), &config.timezones);
        assert_eq!(
            view.timezones
                .iter()
                .map(|row| row.name)
                .collect::<Vec<_>>(),
            ["Etc/UTC", "Asia/Taipei"]
        );
        assert_eq!(view.text, view.timezones[0].time);
        fs::remove_file(&path).unwrap();
        assert!(Config::load(&path).is_err());
    }

    #[test]
    fn invalid_configuration_is_rejected() {
        for text in [
            r#"{"timezones":[]}"#,
            r#"{"timezones":["Invalid/Zone"]}"#,
            r#"{"timezones":"Etc/UTC"}"#,
            r#"{"timezone":["Etc/UTC"]}"#,
            "{}",
            "not json",
        ] {
            assert!(serde_json::from_str::<Config>(text).is_err(), "{text}");
        }
    }
}

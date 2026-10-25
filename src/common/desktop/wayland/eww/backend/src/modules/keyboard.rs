use super::{Refreshable, sysfs::read};
use serde_json::{Value, json};
use std::{fs, io};

pub struct Keyboard;

impl Refreshable for Keyboard {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        data["keyboard"] = keyboard();
        Ok(())
    }
}

fn lock_value(key: &str) -> Option<bool> {
    let Ok(entries) = fs::read_dir("/sys/class/leds") else {
        return None;
    };
    let mut seen = None;
    for entry in entries.flatten() {
        if !entry
            .file_name()
            .to_string_lossy()
            .ends_with(&format!("::{key}"))
        {
            continue;
        }
        match read(entry.path().join("brightness")).as_str() {
            "1" => return Some(true),
            "0" => seen = Some(false),
            _ => (),
        }
    }
    seen
}

fn key_view(label: &str, locked: Option<bool>, expected: bool) -> Value {
    json!({
        "label":label,
        "icon": match locked { Some(true) => "locked", Some(false) => "blank", None => "unknown" },
        "state": match locked { Some(value) if value != expected => "unexpected", None => "unknown", _ => "" },
    })
}

fn keyboard() -> Value {
    json!([
        key_view("S", lock_value("scrolllock"), false),
        key_view("C", lock_value("capslock"), false),
        key_view("N", lock_value("numlock"), true),
    ])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn each_lock_has_its_own_expected_state() {
        assert_eq!(key_view("N", Some(true), true)["state"], "");
        assert_eq!(key_view("N", Some(false), true)["state"], "unexpected");
        assert_eq!(key_view("C", Some(true), false)["state"], "unexpected");
        assert_eq!(key_view("S", None, false)["icon"], "unknown");
        assert_eq!(key_view("N", Some(true), true)["icon"], "locked");
        assert_eq!(key_view("N", Some(false), true)["icon"], "blank");
    }
}

use super::Refreshable;
use crate::command::run;
use serde_json::{Value, json};
use std::io;

pub struct Volume;

impl Refreshable for Volume {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        data["volume"] = volume();
        Ok(())
    }
}

fn volume() -> Value {
    volume_view(run("wpctl", &["get-volume", "@DEFAULT_AUDIO_SINK@"]).as_deref())
}

fn volume_view(value: Option<&str>) -> Value {
    let volume = value
        .and_then(|value| value.strip_prefix("Volume: "))
        .and_then(|value| value.split_whitespace().next())
        .and_then(|value| value.parse::<f64>().ok())
        .filter(|value| value.is_finite());
    let Some(volume) = volume else {
        return json!({"icon":"volume", "percentage":"  ?%", "state":"unknown", "tooltip":"Audio unavailable"});
    };
    let percentage = (volume * 100.0).round() as u32;
    let muted = value.is_some_and(|value| value.contains("MUTED"));
    json!({"icon":if muted { "volume-muted" } else { "volume" }, "percentage":format!("{percentage:3}%"),
        "state":if muted { "muted" } else { "normal" },
        "tooltip":if muted { "Default audio sink (muted)" } else { "Default audio sink" }})
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn audio_preserves_amplification_and_muting() {
        let normal = volume_view(Some("Volume: 1.37"));
        let muted = volume_view(Some("Volume: 1.37 [MUTED]"));
        assert_eq!(normal["percentage"], "137%");
        assert_eq!(muted["percentage"], normal["percentage"]);
        assert_eq!(normal["icon"], "volume");
        assert_eq!(muted["icon"], "volume-muted");
        assert_eq!(
            volume_view(Some("Volume: 0.05 [MUTED]"))["percentage"],
            "  5%"
        );
        assert_eq!(volume_view(None)["state"], "unknown");
    }
}

use super::Refreshable;
use super::calendar::{self, State, Timezones};
use serde_json::Value;
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
        data["clock"] = serde_json::to_value(calendar::clock(now, &State::default(), self.zones))?;
        data["clocks"] = State::load_all()
            .into_iter()
            .map(|(output, state)| {
                Ok((
                    output,
                    serde_json::to_value(calendar::clock(now, &state, self.zones))?,
                ))
            })
            .collect::<Result<serde_json::Map<_, _>, serde_json::Error>>()?
            .into();
        Ok(())
    }
}

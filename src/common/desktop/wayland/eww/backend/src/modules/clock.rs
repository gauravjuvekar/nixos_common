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
        data["clock"] = serde_json::to_value(calendar::clock(
            chrono::Utc::now(),
            &State::load(),
            self.zones,
        ))?;
        Ok(())
    }
}

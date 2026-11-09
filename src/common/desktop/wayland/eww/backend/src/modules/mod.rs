pub mod battery;
pub mod bluetooth;
pub mod calendar;
pub mod clock;
pub mod desktop;
pub mod failed_units;
pub mod inhibitor;
pub mod keyboard;
mod sysfs;
pub mod volume;

use self::calendar::Timezones;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::io;
use std::time::Duration;

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub enum Target {
    Bluetooth,
    FailedUnits,
    Battery,
    Keyboard,
    Volume,
    Clock,
    Inhibitor,
}

pub trait Refreshable: Send {
    /// Update this module's fields.
    /// Preserve the previous values when returning an error.
    fn refresh(&mut self, data: &mut Value) -> io::Result<()>;

    fn interval(&self) -> Duration {
        Duration::from_secs(1)
    }
}

pub fn periodic(zones: &Timezones) -> Vec<(Target, Box<dyn Refreshable>)> {
    vec![
        (Target::Bluetooth, Box::new(bluetooth::Bluetooth)),
        (Target::FailedUnits, Box::new(failed_units::FailedUnits)),
        (Target::Battery, Box::new(battery::Battery)),
        (Target::Keyboard, Box::new(keyboard::Keyboard)),
        (Target::Volume, Box::new(volume::Volume)),
        (Target::Clock, Box::new(clock::Clock::new(zones))),
        (Target::Inhibitor, Box::new(inhibitor::Inhibitor)),
    ]
}

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
use serde_json::Value;
use std::io;
use std::time::Duration;

pub trait Refreshable {
    /// Update this module's fields in the shared snapshot.
    /// Preserve the previous values when returning an error.
    fn refresh(&mut self, data: &mut Value) -> io::Result<()>;

    /// Zero refreshes on every cycle, including cycles triggered by actions.
    fn interval(&self) -> Duration {
        Duration::ZERO
    }
}

// Compositor state is streamed separately so slow status commands cannot delay it.
pub fn periodic(zones: &Timezones) -> Vec<Box<dyn Refreshable + '_>> {
    vec![
        Box::new(bluetooth::Bluetooth),
        Box::new(failed_units::FailedUnits),
        Box::new(battery::Battery),
        Box::new(keyboard::Keyboard),
        Box::new(volume::Volume),
        Box::new(clock::Clock::new(zones)),
        Box::new(inhibitor::Inhibitor),
    ]
}

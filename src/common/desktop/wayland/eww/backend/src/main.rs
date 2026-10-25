mod command;
mod config;
mod modules;
mod refresh;
mod watch;

use clap::{Parser, Subcommand, ValueEnum};
use config::Config;
use modules::{calendar::State, desktop};
use niri_ipc::{Action, WorkspaceReferenceArg};
use std::collections::BTreeSet;
use std::io;
use std::path::PathBuf;
use std::thread;
use std::time::Duration;
use watch::watch;

fn panels() {
    loop {
        let Ok(outputs) = desktop::outputs() else {
            thread::sleep(Duration::from_secs(2));
            continue;
        };
        // Reconcile against the daemon, so a manual reload/close is recovered too.
        if let Some(active) = command::run("eww", &["active-windows"]) {
            let opened: BTreeSet<_> = active
                .lines()
                .filter_map(|line| line.split_once(": "))
                .filter_map(|(id, _)| id.strip_prefix("bar-").map(str::to_string))
                .collect();
            let wanted: BTreeSet<_> = outputs.into_iter().collect();
            for output in wanted.difference(&opened) {
                command::run(
                    "eww",
                    &[
                        "open",
                        "bar",
                        "--id",
                        &format!("bar-{output}"),
                        "--arg",
                        &format!("output={output}"),
                    ],
                );
            }
            for output in opened.difference(&wanted) {
                command::run("eww", &["close", &format!("bar-{output}")]);
            }
        }
        thread::sleep(Duration::from_secs(2));
    }
}

#[derive(Clone, Copy, ValueEnum)]
enum Direction {
    Up,
    Down,
}

impl Direction {
    fn step(self) -> i32 {
        match self {
            Self::Up => 1,
            Self::Down => -1,
        }
    }
}

#[derive(Parser)]
#[command(about = "Desktop status and controls for Eww")]
struct Cli {
    #[arg(long, value_name = "FILE")]
    config: PathBuf,
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Watch,
    Snapshot,
    Panels,
    Workspace { id: u64 },
    Focus { id: u64 },
    Close { id: u64 },
    Timezone { direction: Direction },
    SelectTimezone { name: String },
    CalendarMode,
    Calendar { direction: Direction },
    Volume { direction: Direction },
    Brightness { direction: Direction },
    Mute,
    Inhibit,
    Bluetooth,
}

fn main_command() -> Result<(), Box<dyn std::error::Error>> {
    let args = Cli::parse();
    let config = Config::load(&args.config)?;
    let refresh_action = if matches!(args.command, Command::Bluetooth) {
        "bluetooth"
    } else {
        "action"
    };
    match args.command {
        Command::Watch => return watch(false, &config.timezones).map_err(Into::into),
        Command::Snapshot => return watch(true, &config.timezones).map_err(Into::into),
        Command::Panels => panels(),
        Command::Workspace { id } => desktop::action(Action::FocusWorkspace {
            reference: WorkspaceReferenceArg::Id(id),
        })?,
        Command::Focus { id } => desktop::action(Action::FocusWindow { id })?,
        Command::Close { id } => desktop::action(Action::CloseWindow { id: Some(id) })?,
        Command::Timezone { direction } => {
            State::update(|state| state.shift_timezone(direction.step(), &config.timezones))?;
        }
        Command::SelectTimezone { name } => {
            let timezone = config.timezones.index(&name)?;
            State::update(|state| state.timezone = timezone)?;
        }
        Command::CalendarMode => State::update(|state| {
            state.month_view = !state.month_view;
            state.calendar_offset = 0;
        })?,
        Command::Calendar { direction } => {
            State::update(|state| {
                state.calendar_offset =
                    (state.calendar_offset + direction.step()).clamp(-1000, 1000)
            })?;
        }
        Command::Volume { direction } => {
            let amount = match direction {
                Direction::Up => "5%+",
                Direction::Down => "5%-",
            };
            command::run(
                "wpctl",
                &[
                    "set-volume",
                    "--limit",
                    "2.0",
                    "@DEFAULT_AUDIO_SINK@",
                    amount,
                ],
            )
            .ok_or("Could not change volume")?;
        }
        Command::Brightness { direction } => {
            let amount = match direction {
                Direction::Up => "5%+",
                Direction::Down => "5%-",
            };
            command::run(
                "brightnessctl",
                &[
                    "--class=backlight",
                    "--exponent=4",
                    "--min-value=1",
                    "set",
                    amount,
                ],
            )
            .ok_or("Could not change brightness")?;
        }
        Command::Mute => {
            command::run("wpctl", &["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                .ok_or("Could not toggle mute")?;
        }
        Command::Inhibit => modules::inhibitor::toggle_inhibitor()?,
        Command::Bluetooth => modules::bluetooth::toggle_bluetooth()?,
    }
    refresh::notify(refresh_action);
    Ok(())
}

fn main() {
    if let Err(error) = main_command() {
        if error
            .downcast_ref::<io::Error>()
            .is_some_and(|error| error.kind() == io::ErrorKind::BrokenPipe)
        {
            return;
        }
        eprintln!("bar-status: {error}");
        std::process::exit(1);
    }
}

use super::Refreshable;
use freedesktop_desktop_entry::{DesktopEntry, Iter, default_paths};
use niri_ipc::state::{EventStreamState, EventStreamStatePart};
use niri_ipc::{Action, Event, Reply, Request, Response, Window, Workspace};
use serde_json::{Value, json};
use std::collections::HashMap;
use std::io::{self, BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::Path;
use std::thread;
use std::time::Duration;

pub struct Desktop {
    icons: Icons,
}

impl Desktop {
    pub fn new() -> Self {
        Self {
            icons: Icons::load(),
        }
    }

    pub fn watch(mut publish: impl FnMut(Value) -> io::Result<()>) -> io::Result<()> {
        let compositor = Self::new();
        let mut last_error = None;
        loop {
            let result: io::Result<()> = (|| {
                let mut read = events()?;
                // Rebuild from fresh initial snapshots after every reconnect.
                let mut state = StreamState::default();
                loop {
                    let event = read()?;
                    last_error = None;
                    if let Some(view) = state.apply(event, &compositor.icons) {
                        publish(view)?;
                    }
                }
            })();
            let error: io::Error = result.unwrap_err();
            if error.kind() == io::ErrorKind::BrokenPipe {
                return Err(error);
            }
            let error = error.to_string();
            if last_error.as_ref() != Some(&error) {
                eprintln!("bar-status: {error}");
                last_error = Some(error);
            }
            thread::sleep(Duration::from_secs(1));
        }
    }
}

#[derive(Default)]
struct StreamState {
    state: EventStreamState,
    workspaces_ready: bool,
    windows_ready: bool,
}

impl StreamState {
    fn apply(&mut self, event: Event, icons: &Icons) -> Option<Value> {
        self.workspaces_ready |= matches!(event, Event::WorkspacesChanged { .. });
        self.windows_ready |= matches!(event, Event::WindowsChanged { .. });
        // Layout and focus timestamp events do not affect any displayed field.
        let visible_change = !matches!(
            event,
            Event::WindowLayoutsChanged { .. } | Event::WindowFocusTimestampChanged { .. }
        );
        let unused = self
            .state
            .workspaces
            .apply(event)
            .and_then(|event| self.state.windows.apply(event));
        if unused.is_some() || !visible_change || !self.workspaces_ready || !self.windows_ready {
            return None;
        }
        Some(compositor_view(
            self.state.workspaces.workspaces.values().cloned().collect(),
            self.state.windows.windows.values().cloned().collect(),
            icons,
        ))
    }
}

impl Refreshable for Desktop {
    fn refresh(&mut self, data: &mut Value) -> io::Result<()> {
        for key in ["workspaces", "windows", "titles"] {
            if data.get(key).is_none() {
                data[key] = json!([]);
            }
        }
        let view = compositor(&self.icons)?;
        for (key, value) in view.as_object().unwrap() {
            data[key] = value.clone();
        }
        Ok(())
    }
}

#[derive(Default)]
struct Icons {
    entries: HashMap<String, String>,
}

fn normalize(id: &str) -> String {
    id.trim_end_matches(".desktop").to_lowercase()
}

impl Icons {
    fn load() -> Self {
        let mut icons = Self::default();
        for entry in Iter::new(default_paths()).entries(None::<&[&str]>) {
            icons.insert(&entry);
        }
        icons
    }

    fn insert(&mut self, entry: &DesktopEntry) {
        let Some(icon) = entry.icon() else { return };
        self.entries
            .entry(normalize(&entry.appid))
            .or_insert_with(|| icon.to_string());
        if let Some(class) = entry.startup_wm_class() {
            self.entries
                .entry(normalize(class))
                .or_insert_with(|| icon.to_string());
        }
    }

    fn get(&self, app: &str) -> String {
        self.entries
            .get(&normalize(app))
            .cloned()
            .unwrap_or_else(|| "application-x-executable".into())
    }
}

fn compositor(icons: &Icons) -> io::Result<Value> {
    let Response::Workspaces(workspaces) = request(Request::Workspaces)? else {
        return Err(io::Error::other("Invalid Niri workspaces response"));
    };
    let Response::Windows(windows) = request(Request::Windows)? else {
        return Err(io::Error::other("Invalid Niri windows response"));
    };
    Ok(compositor_view(workspaces, windows, icons))
}

fn compositor_view(
    mut workspaces: Vec<Workspace>,
    mut windows: Vec<Window>,
    icons: &Icons,
) -> Value {
    workspaces.sort_by(|a, b| (&a.output, a.idx).cmp(&(&b.output, b.idx)));
    // Hash-map iteration order must not move taskbar buttons when events arrive.
    windows.sort_by_key(|window| window.id);
    let outputs: HashMap<_, _> = workspaces
        .iter()
        .map(|w| (w.id, w.output.clone()))
        .collect();
    json!({
        "workspaces": workspaces.iter().map(|w| json!({
            "id": w.id, "label": w.name.clone().unwrap_or_else(|| w.idx.to_string()),
            "output": w.output, "state": if w.is_urgent { "urgent" } else if w.is_active { "active" } else { "" },
        })).collect::<Vec<_>>(),
        "windows": windows.iter().map(|w| {
            let app = w.app_id.as_deref().unwrap_or("");
            let icon = icons.get(app);
            json!({ "id": w.id, "title": w.title, "app": app,
                "output": w.workspace_id.and_then(|id| outputs.get(&id)).cloned().flatten(),
                "icon_names": if Path::new(&icon).is_absolute() { vec![] } else { vec![&icon] },
                "icon_files": if Path::new(&icon).is_absolute() { vec![&icon] } else { vec![] },
                "state": match (w.is_focused, w.is_urgent) {
                    (true, true) => "active urgent",
                    (true, false) => "active",
                    (false, true) => "urgent",
                    (false, false) => "",
                } })
        }).collect::<Vec<_>>(),
        "titles": workspaces.iter().filter(|w| w.is_active).map(|w| json!({
            "output": w.output,
            "text": windows.iter().find(|window| Some(window.id) == w.active_window_id)
                .and_then(|window| window.title.as_deref()).unwrap_or(""),
        })).collect::<Vec<_>>(),
    })
}

fn connect() -> io::Result<UnixStream> {
    let path =
        std::env::var_os("NIRI_SOCKET").ok_or_else(|| io::Error::other("NIRI_SOCKET is unset"))?;
    let stream = UnixStream::connect(path)?;
    stream.set_read_timeout(Some(Duration::from_secs(3)))?;
    stream.set_write_timeout(Some(Duration::from_secs(3)))?;
    Ok(stream)
}

fn send(stream: &mut BufReader<UnixStream>, request: Request) -> io::Result<Response> {
    // Keep bounded I/O: niri-ipc's blocking Socket helper has no timeout controls.
    serde_json::to_writer(stream.get_mut(), &request)?;
    writeln!(stream.get_mut())?;
    let mut line = String::new();
    stream.read_line(&mut line)?;
    let reply: Reply = serde_json::from_str(&line)?;
    reply.map_err(|error| io::Error::other(format!("Niri: {error}")))
}

pub fn request(request: Request) -> io::Result<Response> {
    send(&mut BufReader::new(connect()?), request)
}

pub fn events() -> io::Result<impl FnMut() -> io::Result<Event>> {
    event_reader(connect()?)
}

fn event_reader(stream: UnixStream) -> io::Result<impl FnMut() -> io::Result<Event>> {
    let mut stream = BufReader::new(stream);
    if !matches!(send(&mut stream, Request::EventStream)?, Response::Handled) {
        return Err(io::Error::other("Invalid Niri event stream response"));
    }
    // An idle event stream is normal; only the subscription handshake has a timeout.
    stream.get_mut().set_read_timeout(None)?;
    let mut line = String::new();
    Ok(move || {
        line.clear();
        if stream.read_line(&mut line)? == 0 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "Niri disconnected",
            ));
        }
        serde_json::from_str(&line).map_err(Into::into)
    })
}

pub fn action(action: Action) -> io::Result<()> {
    match request(Request::Action(action))? {
        Response::Handled => Ok(()),
        _ => Err(io::Error::other("Invalid Niri action response")),
    }
}

pub fn outputs() -> io::Result<Vec<String>> {
    let Response::Outputs(outputs) = request(Request::Outputs)? else {
        return Err(io::Error::other("Invalid Niri outputs response"));
    };
    Ok(outputs
        .into_iter()
        .filter(|(_, output)| output.current_mode.is_some())
        .map(|(name, _)| name)
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn desktop_icons_use_the_main_section_and_wm_class() {
        let entry = DesktopEntry::from_str(
            "/home/test/.local/share/applications/terminal.desktop",
            "[Desktop Entry]\nIcon=Alacritty\nStartupWMClass=Alacritty\n[Desktop Action new]\nIcon=wrong\n",
            None::<&[&str]>,
        ).unwrap();
        let mut icons = Icons::default();
        icons.insert(&entry);
        assert_eq!(icons.get("terminal.desktop"), "Alacritty");
        assert_eq!(icons.get("ALACRITTY"), "Alacritty");

        let lower_priority = DesktopEntry::from_str(
            "/usr/share/applications/terminal.desktop",
            "[Desktop Entry]\nIcon=other\nStartupWMClass=Alacritty\n",
            None::<&[&str]>,
        )
        .unwrap();
        icons.insert(&lower_priority);
        assert_eq!(icons.get("terminal"), "Alacritty");
        assert_eq!(icons.get("Alacritty.desktop"), "Alacritty");
        assert_eq!(icons.get("unknown"), "application-x-executable");
    }

    #[test]
    fn output_titles_and_task_ids_remain_distinct() {
        let workspaces = serde_json::from_value(json!([
            {"id":17,"idx":1,"name":null,"output":"eDP-1","is_active":true,"is_focused":true,"is_urgent":false,"active_window_id":8},
            {"id":33,"idx":1,"name":null,"output":"DP-1","is_active":true,"is_focused":false,"is_urgent":false,"active_window_id":9}
        ]))
        .unwrap();
        let layout = json!({"tile_size":[800.0,600.0],"window_size":[800,600],"window_offset_in_tile":[0.0,0.0]});
        let windows = serde_json::from_value(json!([
            {"id":8,"title":"same","app_id":"Alacritty","workspace_id":17,"is_focused":true,"is_floating":false,"is_urgent":false,"layout":layout},
            {"id":9,"title":"same","app_id":"Alacritty","workspace_id":33,"is_focused":false,"is_floating":false,"is_urgent":false,"layout":layout}
        ]))
        .unwrap();
        let view = compositor_view(workspaces, windows, &Icons::default());
        assert_eq!(view["windows"][0]["output"], "eDP-1");
        assert_eq!(view["windows"][1]["output"], "DP-1");
        assert_eq!(view["titles"][0]["text"], "same");
    }

    #[test]
    fn window_attention_and_focus_are_independent() {
        let states = [
            (false, false, ""),
            (true, false, "active"),
            (false, true, "urgent"),
            (true, true, "active urgent"),
        ];
        let windows = states
            .iter()
            .enumerate()
            .map(|(id, (focused, urgent, _))| {
                serde_json::from_value(json!({
                    "id": id, "title": "window", "app_id": "Alacritty",
                    "workspace_id": null, "is_focused": focused,
                    "is_floating": false, "is_urgent": urgent,
                    "layout": {"tile_size": [800.0, 600.0], "window_size": [800, 600], "window_offset_in_tile": [0.0, 0.0]},
                }))
                .unwrap()
            })
            .collect();
        let view = compositor_view(vec![], windows, &Icons::default());
        for (window, (_, _, expected)) in view["windows"].as_array().unwrap().iter().zip(states) {
            assert_eq!(window["state"], expected);
        }
    }

    #[test]
    fn streamed_focus_workspace_and_urgency_changes_update_the_view() {
        let mut stream = StreamState::default();
        let icons = Icons::default();
        let workspaces = serde_json::from_value(json!([
            {"id":17,"idx":1,"output":"eDP-1","is_active":true,"is_focused":true,"is_urgent":false,"active_window_id":8},
            {"id":18,"idx":2,"output":"eDP-1","is_active":false,"is_focused":false,"is_urgent":false,"active_window_id":9},
            {"id":33,"idx":1,"output":"DP-1","is_active":true,"is_focused":false,"is_urgent":false,"active_window_id":10}
        ]))
        .unwrap();
        assert!(
            stream
                .apply(Event::WorkspacesChanged { workspaces }, &icons)
                .is_none()
        );
        let layout = json!({"tile_size":[800.0,600.0],"window_size":[800,600],"window_offset_in_tile":[0.0,0.0]});
        let windows = serde_json::from_value(json!([
            {"id":9,"title":"second","workspace_id":18,"is_focused":false,"is_floating":false,"is_urgent":false,"layout":layout},
            {"id":8,"title":"first","workspace_id":17,"is_focused":true,"is_floating":false,"is_urgent":false,"layout":layout},
            {"id":10,"title":"other output","workspace_id":33,"is_focused":false,"is_floating":false,"is_urgent":false,"layout":layout}
        ]))
        .unwrap();
        let view = stream
            .apply(Event::WindowsChanged { windows }, &icons)
            .unwrap();
        assert_eq!(view["windows"][0]["id"], 8);
        assert_eq!(view["windows"][0]["state"], "active");

        let view = stream
            .apply(Event::WindowFocusChanged { id: Some(9) }, &icons)
            .unwrap();
        assert_eq!(view["windows"][0]["state"], "");
        assert_eq!(view["windows"][1]["state"], "active");
        let view = stream
            .apply(
                Event::WorkspaceActivated {
                    id: 18,
                    focused: true,
                },
                &icons,
            )
            .unwrap();
        assert_eq!(view["workspaces"][0]["state"], "active"); // DP-1 remains active.
        assert_eq!(view["workspaces"][1]["state"], "");
        assert_eq!(view["workspaces"][2]["state"], "active");
        assert_eq!(view["titles"][1]["text"], "second");

        let view = stream
            .apply(
                Event::WindowUrgencyChanged {
                    id: 8,
                    urgent: true,
                },
                &icons,
            )
            .unwrap();
        assert_eq!(view["windows"][0]["state"], "urgent");
        let view = stream
            .apply(
                Event::WorkspaceUrgencyChanged {
                    id: 17,
                    urgent: true,
                },
                &icons,
            )
            .unwrap();
        assert_eq!(view["workspaces"][1]["state"], "urgent");
        let view = stream
            .apply(Event::WindowFocusChanged { id: None }, &icons)
            .unwrap();
        assert!(
            view["windows"]
                .as_array()
                .unwrap()
                .iter()
                .all(|w| w["state"] != "active")
        );

        // Removal, including on reconnect, must not leave old buttons behind.
        let view = stream
            .apply(Event::WindowsChanged { windows: vec![] }, &icons)
            .unwrap();
        assert_eq!(view["windows"], json!([]));
        let view = stream
            .apply(Event::WorkspacesChanged { workspaces: vec![] }, &icons)
            .unwrap();
        assert_eq!(view["workspaces"], json!([]));
        assert_eq!(view["titles"], json!([]));
    }

    #[test]
    fn subscription_keeps_events_buffered_with_the_reply_and_reports_disconnect() {
        let (client, mut server) = UnixStream::pair().unwrap();
        // Niri can send the reply and initial events in the same socket write.
        server
            .write_all(b"{\"Ok\":\"Handled\"}\n{\"WindowFocusChanged\":{\"id\":8}}\n")
            .unwrap();
        let mut read = event_reader(client).unwrap();
        assert!(matches!(
            read().unwrap(),
            Event::WindowFocusChanged { id: Some(8) }
        ));
        drop(server);
        assert!(read().is_err());
    }
}

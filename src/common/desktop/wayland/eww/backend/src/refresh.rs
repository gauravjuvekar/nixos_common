use crate::modules::Target;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io;
use std::os::unix::net::UnixDatagram;
use std::path::{Path, PathBuf};

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct Hover {
    pub output: String,
    pub id: u64,
    pub entered: bool,
}

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]
pub enum Message {
    Refresh(Target),
    Hover(Hover),
}

fn socket_path() -> io::Result<PathBuf> {
    xdg::BaseDirectories::new().get_runtime_file("bar-status.sock")
}

pub struct Refresh {
    socket: UnixDatagram,
    path: PathBuf,
}

impl Refresh {
    pub fn listen() -> io::Result<Self> {
        Self::bind(socket_path()?)
    }

    fn bind(path: PathBuf) -> io::Result<Self> {
        match fs::remove_file(&path) {
            Ok(()) => (),
            Err(error) if error.kind() == io::ErrorKind::NotFound => (),
            Err(error) => return Err(error),
        }
        Ok(Self {
            socket: UnixDatagram::bind(&path)?,
            path,
        })
    }

    pub fn receive(&self) -> io::Result<Option<Message>> {
        let mut message = [0; 4096];
        let size = self.socket.recv(&mut message)?;
        Ok(serde_json::from_slice(&message[..size]).ok())
    }
}

impl Drop for Refresh {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.path);
    }
}

pub fn notify(message: Message) {
    if let Ok(path) = socket_path() {
        let _ = send(&path, message);
    }
}

fn send(path: &Path, message: Message) -> io::Result<()> {
    let socket = UnixDatagram::unbound()?;
    socket.set_nonblocking(true)?;
    socket.send_to(&serde_json::to_vec(&message)?, path)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn actions_identify_only_the_source_that_needs_refreshing() {
        let path =
            std::env::temp_dir().join(format!("eww-refresh-test-{}.sock", std::process::id()));
        let watcher = Refresh::bind(path.clone()).unwrap();
        send(&path, Message::Refresh(Target::Clock)).unwrap();
        let start = std::time::Instant::now();
        assert_eq!(
            watcher.receive().unwrap(),
            Some(Message::Refresh(Target::Clock))
        );
        assert!(start.elapsed() < std::time::Duration::from_millis(750));
        send(&path, Message::Refresh(Target::Bluetooth)).unwrap();
        assert_eq!(
            watcher.receive().unwrap(),
            Some(Message::Refresh(Target::Bluetooth))
        );
        let message = Message::Hover(Hover {
            output: "DP-1".into(),
            id: 8,
            entered: true,
        });
        send(&path, message).unwrap();
        assert_eq!(
            watcher.receive().unwrap(),
            Some(Message::Hover(Hover {
                output: "DP-1".into(),
                id: 8,
                entered: true
            }))
        );
        let socket = UnixDatagram::unbound().unwrap();
        socket.send_to(b"unknown", &path).unwrap();
        assert_eq!(watcher.receive().unwrap(), None);
        drop(watcher);
        assert!(!path.exists());
    }
}

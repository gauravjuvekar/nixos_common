use std::fs;
use std::io;
use std::os::unix::net::UnixDatagram;
use std::path::{Path, PathBuf};
use std::time::Duration;

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

    // Clicks interrupt the periodic wait; only Bluetooth needs the slow cache refreshed.
    pub fn wait(&self, duration: Duration) -> bool {
        if duration.is_zero() {
            return false;
        }
        let mut message = [0; 64];
        if self.socket.set_read_timeout(Some(duration)).is_err() {
            return false;
        }
        self.socket
            .recv(&mut message)
            .is_ok_and(|size| &message[..size] == b"bluetooth")
    }
}

impl Drop for Refresh {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.path);
    }
}

pub fn notify(action: &str) {
    if let Ok(path) = socket_path() {
        let _ = send(&path, action);
    }
}

fn send(path: &Path, action: &str) -> io::Result<()> {
    let socket = UnixDatagram::unbound()?;
    socket.set_nonblocking(true)?;
    socket.send_to(action.as_bytes(), path)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn actions_wake_the_watcher_and_bluetooth_invalidates_its_cache() {
        let path =
            std::env::temp_dir().join(format!("eww-refresh-test-{}.sock", std::process::id()));
        let watcher = Refresh::bind(path.clone()).unwrap();
        send(&path, "timezone").unwrap();
        let start = std::time::Instant::now();
        assert!(!watcher.wait(Duration::from_secs(1)));
        assert!(start.elapsed() < Duration::from_millis(750));
        send(&path, "bluetooth").unwrap();
        assert!(watcher.wait(Duration::from_secs(1)));
        drop(watcher);
        assert!(!path.exists());
    }
}

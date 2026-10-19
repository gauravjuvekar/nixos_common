"""Exercise VEY's real socket activation without a systemd user manager."""

import os
import pathlib
import selectors
import signal
import socket
import subprocess
import sys


def tcp_listeners():
    return {
        (table, fields[1])
        for table in ("tcp", "tcp6")
        for line in pathlib.Path(f"/proc/net/{table}").read_text().splitlines()[1:]
        if (fields := line.split())[3] == "0A"
    }


def serve(config, vey, shell, runtime):
    os.umask(0o077)
    runtime = pathlib.Path(runtime)
    directory = runtime / "jailed-codex-vey"
    shared = runtime / "jailed-codex-proxy"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    shared.mkdir(mode=0o700, exist_ok=True)
    listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    assert listener.fileno() == 3
    path = shared / "http.sock"
    listener.bind(str(path))
    os.chmod(path, 0o600)
    listener.listen()
    # These namespaces have no CAP_DAC_OVERRIDE: the kernel must enforce the mode.
    os.chmod(path, 0)
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as denied:
            try:
                denied.connect(str(path))
            except PermissionError:
                pass
            else:
                raise AssertionError("Unix socket permissions were bypassed")
    finally:
        os.chmod(path, 0o600)
    notify = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    notify.bind(str(directory / "notify.sock"))
    notify.settimeout(10)
    backend = None

    def stop(signum, frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        before = tcp_listeners()
        (directory / "ready").touch()
        with selectors.DefaultSelector() as selector:
            selector.register(listener, selectors.EVENT_READ)
            selector.select()
        backend = subprocess.Popen(
            [shell, "-c", 'export LISTEN_PID=$$; exec "$@"', "socket-activated-vey",
             vey, "-c", config, "-C", str(directory)],
            env=os.environ | {
                "NOTIFY_SOCKET": str(directory / "notify.sock"),
                "LISTEN_FDS": "1",
                "LISTEN_FDNAMES": "codex",
            },
            pass_fds=(listener.fileno(),),
        )
        assert b"READY=1" in notify.recv(4096).split(b"\n"), "VEY did not notify readiness"
        assert tcp_listeners() == before, "VEY exposed a TCP listener"
        (directory / "activated").touch()
        raise RuntimeError(f"Shared VEY exited unexpectedly: {backend.wait()}")
    finally:
        if backend is not None:
            backend.terminate()
            try:
                backend.wait(timeout=5)
            except subprocess.TimeoutExpired:
                backend.kill()
                backend.wait()
        listener.close()
        notify.close()
        path.unlink(missing_ok=True)
        (directory / "notify.sock").unlink(missing_ok=True)
        (directory / "ready").unlink(missing_ok=True)


if __name__ == "__main__":
    serve(*sys.argv[1:])

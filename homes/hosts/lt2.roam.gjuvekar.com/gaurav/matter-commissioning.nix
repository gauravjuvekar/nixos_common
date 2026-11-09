{ pkgs, ... }:
let
  proxy = pkgs.python3Packages.matter-ble-proxy;
  commissioning = pkgs.writeShellApplication {
    name = "matter-ble-proxy-rpi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
      proxy
    ];
    text = ''
      usage() {
        echo "Usage: matter-ble-proxy-rpi user@host"
        echo "Keep running while commissioning at http://127.0.0.1:5580"
      }

      if [[ $# -eq 1 && ( "$1" == --help || "$1" == -h ) ]]; then
        usage
        exit 0
      fi

      if [[ $# -ne 1 || -z "''${1:-}" || "''${1:-}" == -* ]]; then
        usage >&2
        exit 2
      fi

      target="$1"
      tunnel_dir=$(mktemp -d -t matter-ble-proxy.XXXXXXXX)
      socket="$tunnel_dir/ssh"

      cleanup() {
        ssh -S "$socket" -O exit "$target" 2>/dev/null || true
        rmdir "$tunnel_dir"
      }
      trap cleanup EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM
      trap 'exit 129' HUP

      # Wait for SSH authentication and forwarding before starting the proxy.
      # The Pi's unauthenticated Matter API stays restricted to loopback.
      ssh -M -S "$socket" -fNT \
        -o ControlPersist=no \
        -o ExitOnForwardFailure=yes \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -L 127.0.0.1:5580:127.0.0.1:5580 \
        "$target"

      echo "Matter dashboard: http://127.0.0.1:5580"
      echo "Use Commission node with the device's setup code and network credentials."
      echo "Keep this terminal open and lt2 near the device; Ctrl+C stops the proxy and tunnel."
      matter-ble-proxy --server ws://127.0.0.1:5580/ble
    '';
  };
in
{
  # Commission on demand using the logged-in user's SSH keys/agent and BlueZ.
  home.packages = [
    proxy
    commissioning
  ];
}

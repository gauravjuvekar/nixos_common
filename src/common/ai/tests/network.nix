# Runs in a private fixture network, including under Nix's normal build sandbox.
{
  pkgs,
  jailedAgents,
  networkOptions,
  sharedProxy,
  allowedDomains,
  hostname,
  configDirs,
}:
let
  inherit (pkgs) lib;
  unitFormat = pkgs.formats.ini { listsAsDuplicateKeys = true; };
  unitFiles = pkgs.linkFarm "jailed-codex-proxy-units" (
    lib.mapAttrsToList (name: unit: {
      name = "${name}.service";
      path = unitFormat.generate "${name}.service" unit;
    }) sharedProxy.services
    ++ lib.mapAttrsToList (name: unit: {
      name = "${name}.socket";
      path = unitFormat.generate "${name}.socket" unit;
    }) sharedProxy.sockets
  );
  proxyFixture = pkgs.writeText "vey-proxy-fixture.py" (builtins.readFile ./proxy-fixture.py);
  privateProxy = import ../vey/service.nix {
    inherit pkgs;
    allowedDomains = [ "private.test" ];
  };
  fixtures = pkgs.writeText "vey-network-fixtures.py" (builtins.readFile ./network-fixtures.py);
  directTargets = [
    "https://192.0.2.1/"
    "https://[2001:db8::1]/"
  ];
  blockedHosts = [
    "example.com"
    "private.test"
    "localhost"
    "127.0.0.1"
    "[::1]"
    "192.0.2.1"
  ];
  fixtureMarker = "vey-network-fixture";
  directProbe = pkgs.writeShellApplication {
    name = "probe-direct-network";
    runtimeInputs = [
      pkgs.curl
      pkgs.python3
    ];
    text = ''
      expected=$1
      for target in ${lib.escapeShellArgs directTargets}; do
        if response=$(curl --silent --show-error --noproxy '*' --cacert "$PWD/ca.pem" \
          --connect-timeout 2 --max-time 3 "$target" 2>connectivity.log); then
          [[ "$response" == ${lib.escapeShellArg fixtureMarker} ]]
          [[ "$expected" == allowed ]] || { echo "Direct access escaped the jail: $target" >&2; exit 1; }
        elif [[ "$expected" == allowed ]]; then
          cat connectivity.log >&2
          echo "Outside-jail connectivity failed: $target" >&2
          exit 1
        fi
      done
      if python3 ${fixtures} udp-probe 2>connectivity.log; then
        [[ "$expected" == allowed ]] || { echo "Direct UDP escaped the jail" >&2; exit 1; }
      elif [[ "$expected" == allowed ]]; then
        cat connectivity.log >&2
        echo "Outside-jail DNS/UDP connectivity failed" >&2
        exit 1
      fi
    '';
  };
  makeProbe =
    name: text:
    jailedAgents.internals.jail name
      (pkgs.writeShellApplication {
        name = "network-probe";
        runtimeInputs = [
          pkgs.curl
          pkgs.coreutils
        ];
        inherit text;
      })
      (
        (import ../restricted-network.nix networkOptions)
        ++ [ jailedAgents.internals.jail.combinators.mount-cwd ]
      );
  publicProbe = makeProbe "vey-public-network-probe" ''
    [[ $(readlink /proc/self/ns/net) != "$1" ]]
    [[ $(cat /etc/hostname) == ${lib.escapeShellArg hostname} ]]
    [[ $(cat /proc/sys/kernel/hostname) == ${lib.escapeShellArg hostname} ]]
    for host in ${lib.escapeShellArgs allowedDomains}; do
      response=$(curl --silent --show-error --cacert "$PWD/ca.pem" --connect-timeout 2 --max-time 3 "https://$host/")
      [[ "$response" == ${lib.escapeShellArg fixtureMarker} ]]
    done
    for target in ${lib.escapeShellArgs blockedHosts}; do
      status=$(curl --silent --max-time 3 --output /dev/null --write-out '%{http_connect}' "https://$target/" || true)
      [[ "$status" == 403 ]] || { echo "Unexpected policy response: $target ($status)" >&2; exit 1; }
    done
    status=$(curl --silent --proxytunnel --max-time 3 --output /dev/null \
      --write-out '%{http_connect}' http://${lib.head allowedDomains}:80/ || true)
    [[ "$status" == 403 ]]
    [[ "$HTTPS_PROXY" == http://127.0.0.1:3128 ]]
    # Anonymous access is allowed, but ordinary HTTP forwarding must stay forbidden.
    status=$(curl --silent --max-time 3 --output /dev/null \
      --write-out '%{http_code}' http://${lib.head allowedDomains}:443/ || true)
    [[ "$status" == 405 ]]
    ${lib.getExe directProbe} blocked
    [[ ! -e /nix/var/nix/daemon-socket/socket ]]
    [[ $(ls -A /run/jailed-codex-proxy) == http.sock ]]
    printf 'Jailed HTTPS allow-list, hostname, ports, anonymous CONNECT, IPv4/IPv6/UDP isolation: passed.\n'
  '';
  privateProbe = makeProbe "vey-private-network-probe" ''
    # This hostname is allowed; the resolved-IP filter must reject its local IP.
    status=$(curl --silent --max-time 3 --output /dev/null --write-out '%{http_connect}' https://private.test/ || true)
    [[ "$status" == 403 ]]
    printf 'Allowed hostname resolving to a private IP: blocked.\n'
  '';
  certificateNames = map (host: "DNS:${host}") (
    lib.unique (
      allowedDomains
      ++ lib.filter (host: !(lib.hasInfix ":" host) && builtins.match "[0-9.]+" host == null) blockedHosts
    )
  );
  fixtureRunner = pkgs.writeShellApplication {
    name = "run-vey-network-checks";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.openssl
      pkgs.python3
      pkgs.iproute2
    ];
    text = ''
      ip link set lo up
      ip address add 192.0.2.1/32 dev lo
      ip -6 address add 2001:db8::1/128 dev lo nodad
      mkdir -p "$HOME/.codex" /tmp/private ${lib.escapeShellArgs configDirs}
      openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
        -keyout /tmp/private/key.pem -out /tmp/private/ca.pem -subj /CN=vey-fixture \
        -addext ${
          lib.escapeShellArg (
            "subjectAltName="
            + lib.concatStringsSep "," (
              certificateNames
              ++ [
                "IP:192.0.2.1"
                "IP:2001:db8::1"
                "IP:127.0.0.1"
                "IP:::1"
              ]
            )
          )
        } >/dev/null 2>&1
      python3 ${fixtures} serve /tmp/private/ca.pem /tmp/private/key.pem /tmp/private/ready &
      fixture_pid=$!
      proxy_pid=
      cleanup() {
        if [[ -n "$proxy_pid" ]]; then
          kill "$proxy_pid" 2>/dev/null || true
          wait "$proxy_pid" 2>/dev/null || true
        fi
        kill "$fixture_pid" 2>/dev/null || true
        wait "$fixture_pid" 2>/dev/null || true
      }
      trap cleanup EXIT
      for ((attempt = 0; attempt < 100; attempt++)); do
        [[ ! -e /tmp/private/ready ]] || break
        kill -0 "$fixture_pid"
        sleep 0.05
      done
      [[ -e /tmp/private/ready ]]
      mkdir /tmp/work
      cd /tmp/work
      cp /tmp/private/ca.pem ca.pem
      for host in ${lib.escapeShellArgs (lib.unique (allowedDomains ++ blockedHosts))}; do
        response=$(curl --silent --show-error --noproxy '*' --cacert "$PWD/ca.pem" \
          --connect-timeout 2 --max-time 3 "https://$host/")
        [[ "$response" == ${lib.escapeShellArg fixtureMarker} ]]
      done
      response=$(curl --silent --show-error --noproxy '*' --connect-timeout 2 --max-time 3 http://${lib.head allowedDomains}:80/)
      [[ "$response" == ${lib.escapeShellArg fixtureMarker} ]]
      ${lib.getExe directProbe} allowed
      printf 'Outside-jail HTTPS, denied destinations, HTTP port 80, direct IPv4/IPv6 and DNS/UDP connectivity: passed.\n'
      export XDG_RUNTIME_DIR=/tmp/runtime
      mkdir -m 700 "$XDG_RUNTIME_DIR"
      start_proxy() {
        python3 ${proxyFixture} "$1" ${lib.getExe sharedProxy.vey} \
          ${pkgs.runtimeShell} "$XDG_RUNTIME_DIR" >/tmp/private/proxy.log 2>&1 &
        proxy_pid=$!
        for ((attempt = 0; attempt < 100; attempt++)); do
          [[ ! -e "$XDG_RUNTIME_DIR/jailed-codex-vey/ready" ]] || break
          kill -0 "$proxy_pid" || { cat /tmp/private/proxy.log >&2; return 1; }
          sleep 0.05
        done
        [[ -e "$XDG_RUNTIME_DIR/jailed-codex-vey/ready" ]]
        # A listening socket alone must not have started the shared backend.
        [[ ! -e "$XDG_RUNTIME_DIR/jailed-codex-vey/activated" ]]
      }
      start_proxy ${sharedProxy.configFile}
      # Concurrent jails must both use this one lazily activated backend.
      ${lib.getExe publicProbe} "$(readlink /proc/self/ns/net)" &
      first_pid=$!
      ${lib.getExe publicProbe} "$(readlink /proc/self/ns/net)" &
      second_pid=$!
      result=0
      wait "$first_pid" || result=1
      wait "$second_pid" || result=1
      if [[ $result != 0 ]]; then cat /tmp/private/proxy.log >&2; exit 1; fi
      [[ -e "$XDG_RUNTIME_DIR/jailed-codex-vey/activated" ]]
      kill -0 "$proxy_pid"
      # Exercise the actual package with the same shared socket.
      "$1" --version
      kill "$proxy_pid"
      wait "$proxy_pid"
      proxy_pid=
      [[ ! -S "$XDG_RUNTIME_DIR/jailed-codex-proxy/http.sock" ]]
      if "$1" --version >/tmp/private/missing-proxy.log 2>&1; then
        echo "Package started without the shared proxy socket" >&2
        exit 1
      fi
      [[ $(cat /tmp/private/missing-proxy.log) == *'systemctl --user start jailed-codex-proxy.socket'* ]]
      rm "$XDG_RUNTIME_DIR/jailed-codex-vey/activated"
      # Restart the same fixture with private.test allowed to isolate the IP filter.
      start_proxy ${privateProxy.configFile}
      ${lib.getExe privateProbe} || { cat /tmp/private/proxy.log >&2; exit 1; }
      kill -0 "$proxy_pid"
      printf 'Unix permissions, socket activation, no TCP listener, concurrent sessions and package startup: passed.\n'
    '';
  };
  passwd = pkgs.writeText "vey-check-passwd" "root:x:0:0:root:/root:/bin/sh\n";
  group = pkgs.writeText "vey-check-group" "root:x:0:\n";
  hosts = pkgs.writeText "vey-check-hosts" "127.0.0.1 localhost\n::1 localhost\n";
  resolv = pkgs.writeText "vey-check-resolv.conf" "nameserver 127.0.0.1\n";
in
pkgs.writeShellApplication {
  name = "test-vey-network";
  runtimeInputs = [ pkgs.coreutils ];
  # Linux requires CAP_SETFCAP to map UID 0 again in the nested jails.
  text = ''
    # Verify dependency ordering and service/socket declarations without a manager.
    unit_runtime=$(mktemp -d)
    trap 'rm -rf -- "$unit_runtime"' EXIT
    XDG_RUNTIME_DIR="$unit_runtime" SYSTEMD_UNIT_PATH=${unitFiles}:${pkgs.systemd}/example/systemd/user \
      ${pkgs.systemd}/bin/systemd-analyze --user --man=no verify \
      ${unitFiles}/*.service ${unitFiles}/*.socket
    rm -rf -- "$unit_runtime"
    trap - EXIT
    # All fixtures and elevated capabilities stay in these private namespaces.
    exec ${lib.getExe pkgs.bubblewrap} --unshare-user --unshare-net --unshare-pid --unshare-uts \
      --uid 0 --gid 0 --cap-add CAP_NET_ADMIN --cap-add CAP_NET_BIND_SERVICE \
      --cap-add CAP_SETFCAP \
      --die-with-parent --ro-bind /nix/store /nix/store --proc /proc --dev /dev --tmpfs /tmp \
      --ro-bind ${passwd} /etc/passwd --ro-bind ${group} /etc/group \
      --ro-bind ${hosts} /etc/hosts --ro-bind ${resolv} /etc/resolv.conf \
      --clearenv --setenv HOME /root --setenv TERM xterm --setenv LANG C.UTF-8 \
      --chdir /tmp ${lib.getExe fixtureRunner} "$@"
  '';
}

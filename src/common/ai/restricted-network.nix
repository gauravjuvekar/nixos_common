{
  pkgs,
  jailedAgents,
  baseJailOptions ? jailedAgents.commonJailOptions,
}:
let
  inherit (pkgs) lib;
in
with jailedAgents.internals.jail.combinators;
lib.filter (
  # Permissions are functions, so exclude network access by its namespace effect.
  permission:
  !((permission {
    includedOnce = [ ];
    namespaces = { };
  }).namespaces.net or false
  )
) baseJailOptions
++ [
  (compose [
    # The excluded network permission also applied the configured hostname.
    (
      state:
      compose [
        (write-text "/etc/hostname" "${state.hostname}\n")
        (unsafe-add-raw-args "--hostname ${escape state.hostname}")
      ] state
    )
    (add-runtime ''
      VEY_RUNTIME="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is required}"
      if [[ ! -S "$VEY_RUNTIME/jailed-codex-proxy/http.sock" ]]; then
        echo "Start the shared proxy with: systemctl --user start jailed-codex-proxy.socket" >&2
        exit 1
      fi
    '')
    # Expose only the data socket directory, never configuration or control sockets.
    (ro-bind (noescape ''"$VEY_RUNTIME/jailed-codex-proxy"'') "/run/jailed-codex-proxy")
    (set-env "HTTP_PROXY" "http://127.0.0.1:3128")
    (set-env "HTTPS_PROXY" "http://127.0.0.1:3128")
    (set-env "http_proxy" "http://127.0.0.1:3128")
    (set-env "https_proxy" "http://127.0.0.1:3128")
    (set-env "NO_PROXY" "")
    (set-env "no_proxy" "")
    (ro-bind "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" "/etc/ssl/certs/ca-certificates.crt")
    (set-env "SSL_CERT_FILE" "/etc/ssl/certs/ca-certificates.crt")
    (wrap-entry (entry: ''
      ${lib.getExe pkgs.socat} TCP4-LISTEN:3128,bind=127.0.0.1,reuseaddr,fork \
        UNIX-CONNECT:/run/jailed-codex-proxy/http.sock 2>/tmp/jailed-codex-proxy-relay.log &
      relay_pid=$!
      ready=false
      for ((attempt = 0; attempt < 100; attempt++)); do
        if ! kill -0 "$relay_pid" 2>/dev/null; then break; fi
        if (echo >/dev/tcp/127.0.0.1/3128) 2>/dev/null; then
          ready=true
          break
        fi
        sleep 0.05
      done
      if ! "$ready"; then
        cat /tmp/jailed-codex-proxy-relay.log >&2
        echo "Jail proxy relay failed to start." >&2
        exit 1
      fi
      exec ${entry}
    ''))
  ])
]

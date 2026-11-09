{
  config,
  lib,
  pkgs,
  ...
}:
let
  backendDomain = "backend.sc.idm.gjuvekar.com";
  certificate = config.security.acme.certs.${backendDomain};
  keyService = config.systemd.services."gcloud-service-account-keys@rpi-sc-idm-acme";
  kanidm = config.services.kanidm.package;
  bootstrap = pkgs.writeShellScript "kanidm-bootstrap" ''
    set -euo pipefail
    umask 077
    # The CLI creates ~/.cache even with an explicit token-cache path.
    export HOME="$RUNTIME_DIRECTORY"
    export KANIDM_TOKEN_CACHE_PATH="$RUNTIME_DIRECTORY/tokens"
    trap '${pkgs.coreutils}/bin/rm -f "$KANIDM_TOKEN_CACHE_PATH"' EXIT

    login_admin() {
      local identity=$1 recovery password
      if ! recovery=$(${kanidm}/bin/kanidmd scripting recover-account "$identity") ||
        ! password=$(${lib.getExe pkgs.jq} -er 'select(.status == "ok") | .output | select(type == "string" and length > 0)' <<< "$recovery"); then
        printf 'Kanidm account recovery failed for %s\n' "$identity" >&2
        ${lib.getExe pkgs.jq} -r '(.message // empty), (.reason // empty)' <<< "$recovery" >&2 || true
        return 1
      fi
      KANIDM_PASSWORD="$password" ${kanidm}/bin/kanidm login --name "$identity"
    }

    ensure_member() {
      local group=$1 member=$2 identity=$3 state
      state=$(${kanidm}/bin/kanidm group get "$group" --name "$identity" --output json)
      if ! ${lib.getExe pkgs.jq} -e --arg member "$member@idm.gjuvekar.com" \
        '(.attrs.member // []) | index($member) != null' <<< "$state" >/dev/null; then
        ${kanidm}/bin/kanidm group add-members "$group" "$member" --name "$identity"
      fi
    }

    # Migrations cannot change built-in groups, so use the CLI.
    login_admin idm_admin
    ensure_member idm_admins gaurav idm_admin
    ensure_member idm_ui_enable_experimental_features idm_admins idm_admin
    policy=$(${kanidm}/bin/kanidm group get idm_all_persons --name idm_admin --output json)
    minimum=$(${lib.getExe pkgs.jq} -r '.attrs.credential_type_minimum[0] // "any"' <<< "$policy")
    case "$minimum" in
      passkey|attested_passkey|attested_residentkey) ;;
      *) ${kanidm}/bin/kanidm group account-policy credential-type-minimum idm_all_persons passkey --name idm_admin ;;
    esac
    ${kanidm}/bin/kanidm logout --name idm_admin
    login_admin admin
    ensure_member system_admins gaurav admin
    ${kanidm}/bin/kanidm logout --name admin
  '';
in
{
  networking.hosts."127.0.0.1" = [ backendDomain ];

  services.kanidm = {
    package = pkgs.kanidm_1_11;
    server = {
      enable = true;
      settings = {
        domain = "idm.gjuvekar.com";
        origin = "https://idm.gjuvekar.com";
        bindaddress = "127.0.0.1:8443";
        tls_chain = "${certificate.directory}/fullchain.pem";
        tls_key = "${certificate.directory}/key.pem";
        http_client_address_info.x-forward-for = [ "127.0.0.1" ];
        online_backup.versions = 7;
      };
      # Run these migrations only on the Pi when adding replicas.
      entryManagement.migrations = {
        "10-persons" = {
          id = "3ac43825-a196-5f05-93ea-9b4435a481e3";
          assertions = [
            {
              state = "present";
              id = "582ae061-c07b-5a21-a303-73d91aa88169";
              class = [
                "person"
                "account"
              ];
              name = "gaurav";
              displayname = "Gaurav";
            }
          ];
        };
      };
    };
    client = {
      enable = true;
      settings.uri = "https://idm.gjuvekar.com";
    };
  };

  security.acme = {
    acceptTerms = true;
    certs.${backendDomain} = {
      # The backend's CAA must allow lego's ACME account.
      server = config.services.caddy.acmeCA;
      dnsProvider = "gcloud";
      group = "kanidm";
      reloadServices = [ "kanidm.service" ];
      # lego follows the existing _acme-challenge CNAME into backend-acme.
      dnsResolver = "1.1.1.1:53,[2606:4700:4700::1111]:53";
    };
  };

  systemd.services."acme-order-renew-${backendDomain}" = {
    requires = [ keyService.name ];
    after = [ keyService.name ];
    environment = {
      GCE_PROJECT = "gjuvekar-com-infra";
      GCE_ZONE_ID = "rpi-sc";
      GCE_SERVICE_ACCOUNT_FILE = "/run/kanidm-acme/gcp-credentials.json";
    };
    preStart = ''
      umask 077
      ${lib.getExe pkgs.jq} -n \
        --rawfile privateKey "$CREDENTIALS_DIRECTORY/private-key.pem" \
        --arg email ${lib.escapeShellArg keyService.environment.KEY_NAME} \
        '{type: "service_account", project_id: "gjuvekar-com-infra",
          client_email: $email, private_key: $privateKey,
          token_uri: "https://oauth2.googleapis.com/token"}' \
        > "$RUNTIME_DIRECTORY/gcp-credentials.json"
    '';
    serviceConfig = {
      LoadCredential = [ "private-key.pem:${keyService.environment.PRIVATE_KEY_PATH}" ];
      RuntimeDirectory = "kanidm-acme";
      RuntimeDirectoryMode = "0700";
    };
  };

  systemd.services.kanidm = {
    # Start after ACME has issued a trusted certificate.
    requires = [ "acme-order-renew-${backendDomain}.service" ];
    after = [ "acme-order-renew-${backendDomain}.service" ];
    serviceConfig.ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
  };

  systemd.services.kanidm-bootstrap = {
    description = "Bootstrap Kanidm administrator roles and person passkey policy";
    wantedBy = [ "multi-user.target" ];
    requires = [ "kanidm.service" ];
    after = [ "kanidm.service" ];
    partOf = [ "kanidm.service" ];
    # recover-account rotates the admin and idm_admin passwords on each run.
    # Passwords stay in memory. The token cache is deleted on exit.
    environment.KANIDM_URL = "https://${backendDomain}:8443";
    serviceConfig = {
      Type = "oneshot";
      User = "kanidm";
      Group = "kanidm";
      ExecStart = bootstrap;
      RuntimeDirectory = "kanidm-bootstrap";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = "no";
      UMask = "0077";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
    };
  };
}

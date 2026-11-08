{
  lib,
  pkgs,
  ...
}:
let
  accounts = [
    "rpi-sc-ddns"
    "rpi-sc-ingress-acme"
    "rpi-sc-idm-acme"
  ];
  generator = pkgs.writeShellScript "generate-gcloud-service-account-keys" ''
    # Run by gcloud-service-account-keys@.service; never send private keys to Google.
    set -euo pipefail
    umask 077

    if [ "$#" -ne 4 ]; then
      echo "Usage: generate-gcloud-service-account-keys KEY_NAME PRIVATE_KEY_PATH PUBLIC_KEY_PATH CERTIFICATE_PATH" >&2
      exit 2
    fi
    account=$1
    private_key=$2
    public_key=$3
    certificate=$4
    : "''${STATE_DIRECTORY:?systemd must supply the private state directory}"
    exec 9>"$STATE_DIRECTORY/.lock"
    ${pkgs.util-linux}/bin/flock --exclusive 9

    work_dir=$(${pkgs.coreutils}/bin/mktemp -d "$STATE_DIRECTORY/.generate.XXXXXXXX")
    trap '${pkgs.coreutils}/bin/rm -rf -- "$work_dir"' EXIT

    if [ ! -e "$private_key" ]; then
      # Refuse to replace the identity of possibly already uploaded public material.
      if [ -e "$certificate" ] || [ -e "$public_key" ]; then
        echo "$account: private key missing but public material exists; restore the key or explicitly rotate this account" >&2
        exit 1
      fi
      ${pkgs.openssl}/bin/openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 \
        -out "$work_dir/private-key.pem" 2>"$work_dir/keygen.log"
      ${pkgs.coreutils}/bin/chmod 0600 "$work_dir/private-key.pem"
      ${pkgs.coreutils}/bin/mv -T "$work_dir/private-key.pem" "$private_key"
    fi

    # Check existing keys without ever replacing them, including after interruption.
    ${pkgs.coreutils}/bin/chmod 0600 "$private_key"
    ${pkgs.openssl}/bin/openssl pkey -in "$private_key" -passin pass: -check -noout > /dev/null
    ${pkgs.openssl}/bin/openssl pkey -in "$private_key" -passin pass: -pubout -out "$work_dir/public-key.pem"
    if [ -e "$public_key" ]; then
      ${pkgs.diffutils}/bin/cmp --silent "$public_key" "$work_dir/public-key.pem" || {
        echo "$account: public key does not match private key" >&2
        exit 1
      }
    else
      ${pkgs.coreutils}/bin/mv -T "$work_dir/public-key.pem" "$public_key"
    fi

    if [ ! -e "$certificate" ]; then
      # Google requires a PEM X.509 v3 certificate wrapping an RSA public key.
      # The generic subject contains no hostnames or service account identity.
      # RFC 5280 represents no defined expiry with 9999-12-31 23:59:59 UTC.
      ${pkgs.openssl}/bin/openssl req -new -x509 -sha256 -not_after 99991231235959Z \
        -key "$private_key" -passin pass: -subj /CN=unused \
        -addext basicConstraints=critical,CA:FALSE \
        -addext keyUsage=critical,digitalSignature \
        -out "$work_dir/certificate.pem"
      ${pkgs.coreutils}/bin/mv -T "$work_dir/certificate.pem" "$certificate"
    fi
    ${pkgs.openssl}/bin/openssl x509 -in "$certificate" -pubkey -noout > "$work_dir/certificate-public-key.pem"
    ${pkgs.diffutils}/bin/cmp --silent "$public_key" "$work_dir/certificate-public-key.pem" || {
      echo "$account: certificate does not match private key" >&2
      exit 1
    }
    ${pkgs.openssl}/bin/openssl verify -CAfile "$certificate" "$certificate" > /dev/null
    ${pkgs.coreutils}/bin/chmod 0600 "$public_key" "$certificate"
    echo "$account: public certificate $certificate"
  '';
in
{
  systemd.services = {
    "gcloud-service-account-keys@" = {
      description = "Generate local Google Cloud service account key for %i";
      after = [ "time-sync.target" ];
      wants = [ "time-sync.target" ];
      enableDefaultPath = false;
      serviceConfig = {
        # systemd expands each instance variable into a separate argument.
        ExecStart = ''${generator} "''${KEY_NAME}" "''${PRIVATE_KEY_PATH}" "''${PUBLIC_KEY_PATH}" "''${CERTIFICATE_PATH}"'';
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
        StateDirectory = "gcloud-service-account-keys/%i";
        StateDirectoryMode = "0700";
        UMask = "0077";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateNetwork = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
      };
    };
  }
  // lib.listToAttrs (
    map (
      account:
      lib.nameValuePair "gcloud-service-account-keys@${account}" {
        overrideStrategy = "asDropin";
        enableDefaultPath = false;
        wantedBy = [ "multi-user.target" ];
        environment = {
          KEY_NAME = "${account}@gjuvekar-com-infra.iam.gserviceaccount.com";
          PRIVATE_KEY_PATH = "/var/lib/gcloud-service-account-keys/${account}/private-key.pem";
          PUBLIC_KEY_PATH = "/var/lib/gcloud-service-account-keys/${account}/public-key.pem";
          CERTIFICATE_PATH = "/var/lib/gcloud-service-account-keys/${account}/certificate.pem";
        };
      }
    ) accounts
  );
}

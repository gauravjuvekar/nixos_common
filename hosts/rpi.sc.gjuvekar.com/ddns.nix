{
  config,
  lib,
  pkgs,
  ...
}:
let
  keyService = config.systemd.services."gcloud-service-account-keys@rpi-sc-ddns";
  project = "gjuvekar-com-infra";
  zone = "rpi-sc";
  domain = "rpi.sc.gjuvekar.com";
  # Go consults /etc/hosts even with a custom DNS resolver. NixOS maps this
  # machine's own FQDN to 127.0.0.2, which is not its published DNS address.
  resolverHosts = pkgs.writeText "ddns-updater-hosts" ''
    127.0.0.1 localhost
    ::1 localhost
  '';
  resolverConfig = pkgs.writeText "ddns-updater-resolv.conf" ''
    nameserver 1.1.1.1
    nameserver 2606:4700:4700::1111
    options timeout:2 attempts:2
  '';
  # ddns-updater 2.10.0 otherwise sends ttl=0 in its GCP PATCH request.
  # Carry the existing record TTL through to the address update.
  preserveTtl = pkgs.writeText "ddns-updater-gcp-preserve-ttl.patch" ''
    --- a/internal/provider/providers/gcp/update.go
    +++ b/internal/provider/providers/gcp/update.go
    @@ -48,7 +48,7 @@
     		return ip, nil
     	}

    -	err = p.patchRRSet(ctx, client, fqdn, recordType, ip)
    +	err = p.patchRRSet(ctx, client, fqdn, recordType, ip, recordResourceSet.TTL)
     	if err != nil {
     		return netip.Addr{}, fmt.Errorf("updating record: %w", err)
     	}
    --- a/internal/provider/providers/gcp/api.go
    +++ b/internal/provider/providers/gcp/api.go
    @@ -102,7 +102,7 @@
     }

     func (p *Provider) patchRRSet(ctx context.Context, client *http.Client, fqdn, recordType string,
    -	ip netip.Addr,
    +	ip netip.Addr, ttl uint32,
     ) (err error) {
     	urlPath := fmt.Sprintf("/dns/v1/projects/%s/managedZones/%s/rrsets/%s/%s",
     		p.project, p.zone, fqdn, recordType)
    @@ -112,6 +112,7 @@
     		Name:    fqdn,
     		Rrdatas: []string{ip.String()},
     		Type:    recordType,
    +		TTL:     ttl,
     	}
     	err = encoder.Encode(rrSet)
     	if err != nil {
  '';
  updater = pkgs.ddns-updater.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ preserveTtl ];
  });
  settings =
    map
      (
        ipVersion:
        {
          provider = "gcp";
          inherit project zone domain;
          ip_version = ipVersion;
        }
        // lib.optionalAttrs (ipVersion == "ipv6") {
          # Stable EUI-64 suffix of enabcm6e4ei0 (dc:a6:32:bb:35:08).
          # The public /64 prefix is discovered afresh on each check.
          ipv6_suffix = "::dea6:32ff:febb:3508/64";
        }
      )
      [
        "ipv4"
        "ipv6"
      ];
  configTemplate = pkgs.writeText "ddns-updater-config.json" (
    builtins.toJSON {
      inherit settings;
    }
  );
in
{
  services.ddns-updater = {
    enable = true;
    package = updater;
    environment = {
      PERIOD = "10m";
      CONFIG_FILEPATH = "/run/ddns-updater/config.json";
      # Use encrypted DNS to discover the Internet-visible addresses, also
      # allowing IPv4 NAT if the Pi later stops receiving a public DHCP lease.
      PUBLICIP_FETCHERS = "dns";
      PUBLICIP_DNS_PROVIDERS = "cloudflare";
      SERVER_ENABLED = "no";
      HEALTH_SERVER_ADDRESS = "";
    };
  };

  systemd.services.ddns-updater = {
    requires = [ "${keyService.name}" ];
    after = [
      "${keyService.name}"
      "time-sync.target"
    ];
    wants = [ "time-sync.target" ];
    preStart = ''
      umask 077
      # Assemble credentials only in /run, using systemd's private key copy.
      # Google JWT authentication permits an omitted private_key_id.
      ${lib.getExe pkgs.jq} \
        --rawfile privateKey "$CREDENTIALS_DIRECTORY/private-key.pem" \
        --arg email ${lib.escapeShellArg keyService.environment.KEY_NAME} \
        ' .settings |= map(. + {credentials: {
          type: "service_account", project_id: .project,
          client_email: $email, private_key: $privateKey,
          token_uri: "https://oauth2.googleapis.com/token"
        }}) ' \
        ${configTemplate} > "$RUNTIME_DIRECTORY/config.json"
    '';
    serviceConfig = {
      # The default Go resolver supports fallback across these IPv4/IPv6
      # nameservers; RESOLVER_ADDRESS only accepts a single endpoint.
      BindReadOnlyPaths = [
        "${resolverHosts}:/etc/hosts"
        "${resolverConfig}:/etc/resolv.conf"
      ];
      LoadCredential = [ "private-key.pem:${keyService.environment.PRIVATE_KEY_PATH}" ];
      RuntimeDirectory = "ddns-updater";
      RuntimeDirectoryMode = "0700";
      StateDirectoryMode = "0700";
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

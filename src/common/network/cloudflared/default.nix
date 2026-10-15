{
  config,
  inputs,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
  isClient = hostinfo.isLocalGraphical && lib.strings.hasSuffix ".gjuvekar.com" hostinfo.fqdn;
  tunnelServers = lib.filter (
    server: server.hostinfo.isRemotelyAccessible && server.hostinfo.fqdn != hostinfo.fqdn
  ) (map (host: host.config) (lib.attrValues inputs.self.nixosConfigurations));
  tunnelSshSettings = lib.listToAttrs (
    map (
      server:
      let
        remote = server.hostinfo;
        tunnelHostname = "ssh-cftun-${remote.hostname}-${remote.domainname}";
      in
      lib.nameValuePair "cftun.${remote.fqdn} ssh.cftun.${remote.fqdn} ${tunnelHostname}" {
        HostName = tunnelHostname;
        User = if remote.primaryUsername == null then "root" else remote.primaryUsername;
        ProxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      }
    ) tunnelServers
  );
in
{
  config =
    {
      "home-manager" = lib.mkIf isClient {
        home.packages = [ pkgs.cloudflared ];
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = tunnelSshSettings;
        };
      };
      "nixos-system" = lib.mkMerge [
        {
          environment.systemPackages = lib.optionals hostinfo.isRemotelyAccessible [ pkgs.cloudflared ];
        }
        (lib.mkIf hostinfo.isRemotelyAccessible {
          age.secrets.cloudflared-token = {
            rekeyFile = ../../../../keys/secrets + "/cloudflared-token-cftun.${hostinfo.fqdn}.age";
            mode = "0400";
          };

          # Remotely managed tunnel: configure the SSH hostname in Cloudflare.
          # The pinned services.cloudflared module only supports local credentials JSON.
          systemd.services.cloudflared-ssh = {
            description = "Cloudflare Tunnel for SSH";
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [
              "network-online.target"
              "sshd.service"
            ];
            # Keep retrying even if the network is unavailable during boot.
            startLimitIntervalSec = 0;
            restartTriggers = [ config.age.secrets.cloudflared-token.file ];

            serviceConfig = {
              ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/token";
              LoadCredential = "token:${config.age.secrets.cloudflared-token.path}";
              DynamicUser = true;
              Restart = "always";
              RestartSec = "10s";
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = true;
              ProtectSystem = "strict";
            };
          };
        })
      ];
    }
    ."${moduleContext}";
}

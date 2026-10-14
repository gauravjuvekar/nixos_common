{
  config,
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
in
{
  config =
    {
      "home-manager" = lib.mkIf isClient {
        home.packages = [ pkgs.cloudflared ];
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."cftun.dt.sc.gjuvekar.com ssh.cftun.dt.sc.gjuvekar.com ssh-cftun-dt-sc.gjuvekar.com" = {
            HostName = "ssh-cftun-dt-sc.gjuvekar.com";
            ProxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
          };
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

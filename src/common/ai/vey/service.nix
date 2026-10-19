# One socket-activated VEY process for all jails; Unix permissions control access.
{
  pkgs,
  allowedDomains,
}:
let
  inherit (pkgs) lib;
  vey = pkgs.callPackage ./package.nix { };
  configFile = pkgs.writeText "jailed-codex-vey.json" (
    builtins.toJSON {
      runtime.thread_number = 1;
      log = "stdout";
      user_group = [
        {
          name = "session";
          anonymous_user = {
            name = "codex";
            proxy_request_filter.permit = [ "HttpConnect" ];
          };
        }
      ];
      server = [
        {
          name = "codex";
          type = "http_proxy";
          escaper = "public";
          user_group = "session";
          allow_custom_host = false;
          log_uri_max_chars = 0;
          dst_host_filter_set.exact_match = {
            default = "forbid";
            permit = allowedDomains;
          };
          dst_port_filter = {
            default = "forbid";
            permit = [ 443 ];
          };
        }
      ];
      resolver = [
        {
          name = "system";
          type = "c-ares";
        }
      ];
      escaper = [
        {
          name = "public";
          type = "direct_fixed";
          resolver = "system";
          # Also check resolved IPs, so an allowed name cannot reach host/LAN services.
          egress_network_filter = {
            default = "permit";
            forbid = [
              "0.0.0.0/8"
              "10.0.0.0/8"
              "100.64.0.0/10"
              "127.0.0.0/8"
              "169.254.0.0/16"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "224.0.0.0/4"
              "240.0.0.0/4"
              "::/96"
              "::ffff:0:0/96"
              "64:ff9b::/96"
              "64:ff9b:1::/48"
              "100::/64"
              "fc00::/7"
              "fe80::/10"
              "ff00::/8"
            ];
          };
        }
      ];
    }
  );
in
{
  inherit vey configFile;
  sockets.jailed-codex-proxy = {
    Unit.Description = "Shared restricted Codex proxy socket";
    Socket = {
      ListenStream = "%t/jailed-codex-proxy/http.sock";
      SocketMode = "0600";
      DirectoryMode = "0700";
      RemoveOnStop = true;
      FileDescriptorName = "codex";
    };
    Install.WantedBy = [ "sockets.target" ];
  };
  services = {
    jailed-codex-proxy = {
      Unit = {
        Description = "Shared socket-activated VEY proxy for restricted Codex jails";
        Requires = [ "jailed-codex-proxy.socket" ];
        After = [ "jailed-codex-proxy.socket" ];
      };
      Service = {
        Type = "notify";
        ExecStart = "${lib.getExe vey} -c ${configFile} -C %t/jailed-codex-vey";
        RuntimeDirectory = "jailed-codex-vey";
        RuntimeDirectoryMode = "0700";
        TimeoutStartSec = 10;
        Restart = "on-failure";
        UMask = "0077";
        NoNewPrivileges = true;
      };
    };
  };
}

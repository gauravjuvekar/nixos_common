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
in
{
  config =
    {
      "home-manager" = {
        home.packages = lib.lists.optionals hostinfo.isLocalInteractive [
          pkgs.sshfs
          pkgs.sshpass
        ];
      };

      "nixos-system" = {
        networking.firewall = {
          allowedTCPPorts = [ 22 ];
          allowedUDPPorts = [ 22 ];
        };

        services.openssh = {
          enable = true;
          settings = {
            KbdInteractiveAuthentication = false;
            PasswordAuthentication = false;
          };

          extraConfig = lib.mkIf (lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname) (
            let
              trusted_ca_keys = pkgs.concatTextFile {
                name = "sshd-ca-keys";
                files = [
                  ../../../keys/yk5a-22897261-ssh-signing-key.pub
                  ../../../keys/yk5c-24251755-ssh-signing-key.pub
                ];
                destination = "/ssh_trusted_ca_keys";
              };
            in
            ''
              TrustedUserCAKeys ${trusted_ca_keys}/ssh_trusted_ca_keys
            ''
          );
        };
      };
    }
    ."${moduleContext}";
}

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
    lib.mkIf hostinfo.isLocalInteractive
      {
        "home-manager" = {
          home.packages = lib.lists.flatten [
            (lib.lists.optional hostinfo.isLocalGraphical pkgs.yubioath-flutter)
            pkgs.age-plugin-yubikey
            pkgs.libfido2
            pkgs.yubikey-manager
          ];

          programs.gpg = {
            scdaemonSettings = {
              disable-ccid = true;
              reader-port = "Yubico Yubi";
            };
          };
        };
        "nixos-system" = {
          security.pam = {
            services."sudo".u2fAuth = true;
            u2f.settings = {
              authfile = "/home/%u/.config/pam_sudo/pam_u2f_authorized_keys";
              cue = true;
              expand = true;
              origin = "pam://${config.networking.fqdn}";
            };
          };

          security.polkit.enable = true;
          services.pcscd.enable = true;
        };
      }
      ."${moduleContext}";
}

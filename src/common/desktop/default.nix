{
  config,
  lib,
  moduleContext,
  osConfig ? null,
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
        };

        "nixos-system" = {
          services.libinput.enable = true;
          users.users."${hostinfo.primaryUsername}".extraGroups = [
            "input"
          ];

          services.gnome.gnome-keyring.enable = true;
        };
      }
      ."${moduleContext}";
}

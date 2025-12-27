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
    lib.mkIf hostinfo.isLocalGraphical
      {
        "home-manager" = {
        };

        "nixos-system" = {
          services.displayManager = {
            gdm.enable = true;
          };

          environment.systemPackages = [
            pkgs.vanilla-dmz # 1 cursor theme requried for gdm
          ];
        };
      }
      ."${moduleContext}";
}

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
          environment.systemPackages = [
            pkgs.arandr
            pkgs.xorg.xkill
          ];
        };
      }
      ."${moduleContext}";
}

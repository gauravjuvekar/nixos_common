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
      "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
        home.packages = lib.lists.flatten [
          (lib.lists.optional hostinfo.isLocalGraphical pkgs.gnome-system-monitor)
          pkgs.atop
          pkgs.htop
          pkgs.iotop
          pkgs.psmisc
        ];
      };
      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

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
      };
      "nixos-system" = {
        environment.systemPackages = lib.lists.optionals hostinfo.isLocalInteractive [
          pkgs.lm_sensors
          pkgs.lshw
          pkgs.pciutils
          pkgs.usbutils
        ];
      };
    }
    ."${moduleContext}";
}

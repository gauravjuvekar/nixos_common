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
        home.packages = lib.lists.optionals hostinfo.isLocalGraphical [
          pkgs.brightnessctl
          pkgs.ddcutil
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

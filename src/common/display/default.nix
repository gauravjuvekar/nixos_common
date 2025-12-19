{
  config,
  lib,
  pkgs,
  osConfig ? null,
  moduleContext,
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
    if moduleContext == "home-manager" then
      {
        home.packages = lib.lists.optionals hostinfo.isLocalGraphical [
          pkgs.brightnessctl
          pkgs.ddcutil
        ];
      }
    else
      { };
}

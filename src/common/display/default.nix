{
  config,
  lib,
  pkgs,
  osConfig ? null,
  moduleContext,
  ...
}:
let
  hostinfo = if (!builtins.isNull osConfig) then osConfig.hostinfo else config.hostinfo;
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

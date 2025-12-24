{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  usageinfo =
    {
      home-manager = osConfig.usageinfo;
      nixos-system = config.usageinfo;
    }
    ."${moduleContext}";
in
{
  config =
    {
      "home-manager" = {
        home.packages = lib.lists.optionals (builtins.elem "2d" usageinfo.cadTools) [
          pkgs.gimp-with-plugins
          pkgs.inkscape
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

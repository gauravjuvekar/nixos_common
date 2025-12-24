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
        home.packages = lib.lists.optionals (builtins.elem "3d" usageinfo.cadTools) [
          pkgs.blender
          pkgs.freecad
          pkgs.openscad
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

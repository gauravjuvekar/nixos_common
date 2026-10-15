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
      "home-manager" = lib.mkIf hostinfo.isLocalGraphical {
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

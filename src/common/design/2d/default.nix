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
        home.packages = lib.lists.optionals (builtins.elem "2d" usageinfo.cadTools) [
          pkgs.darktable
          pkgs.gimp-with-plugins
          pkgs.inkscape
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

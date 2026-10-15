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
        home.packages = lib.lists.optionals (builtins.elem "eda" usageinfo.cadTools) [
          pkgs.kicad
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

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
        home.packages =
          lib.lists.optionals hostinfo.isLocalInteractive [
            pkgs.hexedit
            pkgs.hexyl
            pkgs.xxd
          ]
          ++ lib.lists.optionals hostinfo.isLocalGraphical [
            pkgs.imhex
          ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

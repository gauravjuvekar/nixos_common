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
      "home-manager" = lib.mkIf hostinfo.isLocalGraphical {
        home.packages = [
          pkgs.seahorse
        ];
      };
      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

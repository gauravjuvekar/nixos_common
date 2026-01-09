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
        home.packages = lib.lists.flatten (
          lib.lists.optionals hostinfo.isLocalGraphical [
            pkgs.baobab
          ]
          ++ lib.lists.optionals hostinfo.isLocalInteractive [
            pkgs.dust
            pkgs.fclones
          ]
        );
      };

      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

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
          lib.lists.optionals (builtins.elem "db" usageinfo.devTools) [
            pkgs.mariadb
            pkgs.postgresql
            pkgs.sqlite
            (lib.lists.optional hostinfo.isLocalGraphical pkgs.sqlitebrowser)
            pkgs.sqlx-cli
          ]
        );
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

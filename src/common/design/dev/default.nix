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
        home.packages = lib.lists.optionals (usageinfo.devLangs != [ ]) [
          pkgs.lspmux
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

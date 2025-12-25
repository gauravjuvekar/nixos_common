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
        home.packages = lib.lists.optionals (builtins.elem "memory" usageinfo.devTools) [
          pkgs.heaptrack
          pkgs.valgrind
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

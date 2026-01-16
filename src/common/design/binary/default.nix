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
        home.packages = lib.lists.optionals (builtins.elem "binary" usageinfo.devTools) [
          pkgs.bintools
          # pkgs.elf-dissector # broken
          pkgs.elf-info
          pkgs.elfutils
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

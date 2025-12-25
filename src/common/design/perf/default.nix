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
        home.packages = lib.lists.optionals (builtins.elem "perf" usageinfo.devTools) [
          pkgs.cargo-flamegraph
          pkgs.flamegraph
          pkgs.hotspot
          pkgs.hyperfine
          pkgs.inferno
        ];
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

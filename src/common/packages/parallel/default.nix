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
        home.packages = [
          (lib.hiPrio pkgs.parallel) # Because moreutils overwrites it
        ];

        home.file.".parallel/will-cite" = {
          enable = true;
          text = "";
        };
      };
      "nixos-system" = {
        environment.systemPackages = [
          pkgs.parallel
        ];
      };
    }
    ."${moduleContext}";
}

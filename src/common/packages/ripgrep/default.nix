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
      "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
        home.packages = [
          pkgs.repgrep
        ];
        home.shellAliases = {
          "rgc" = "rg --color=always";
        };
      };
      "nixos-system" = {
        environment.systemPackages = [
          pkgs.ripgrep
        ];
      };
    }
    ."${moduleContext}";
}

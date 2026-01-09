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
    lib.mkIf hostinfo.isLocalInteractive
      {
        "home-manager" = {
          home.packages = [
            pkgs.fd
            pkgs.findutils
          ];

          home.shellAliases = {
            "fn" = "find . -name";
          };
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

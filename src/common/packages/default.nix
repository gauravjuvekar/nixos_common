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
      };
      "nixos-system" = {
        environment.systemPackages = [
          pkgs.curl
          pkgs.fd
          pkgs.tree
          pkgs.wget
        ];
      };
    }
    ."${moduleContext}";
}

{
  config,
  lib,
  moduleContext,
  osConfig ? null,
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
      "home-manager" = { };
      "nixos-system" = {
        networking.firewall = {
          enable = true;
          allowedTCPPortRanges = lib.lists.flatten [
            (lib.lists.optional (lib.lists.elem "network" usageinfo.devTools) {
              from = 8000;
              to = 8999;
            })
          ];
          allowedUDPPortRanges = lib.lists.flatten [
            (lib.lists.optional (lib.lists.elem "network" usageinfo.devTools) {
              from = 8000;
              to = 8999;
            })
          ];
        };
      };
    }
    ."${moduleContext}";
}

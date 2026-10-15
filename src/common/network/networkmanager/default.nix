{
  config,
  lib,
  moduleContext,
  osConfig ? null,
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
        "home-manager" = { };
        "nixos-system" = {
          networking.networkmanager.enable = true;
          networking.useDHCP = lib.mkDefault true;

          users.users = lib.mkIf (hostinfo.primaryUsername != null) {
            "${hostinfo.primaryUsername}".extraGroups = [ "networkmanager" ];
          };
        };
      }
      ."${moduleContext}";
}

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
    lib.mkIf hostinfo.isLaptop
      {
        "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
          home.packages = lib.lists.optionals hostinfo.isLaptop [
            pkgs.gnome-power-manager
            pkgs.powerstat
            pkgs.powertop
          ];
        };
        "nixos-system" = {
          services.logind.settings.Login = {
            HandleLidSwitch = "ignore";
            HandleLidSwitchDocked = "ignore";
            HandleLidSwitchExternalPower = "ignore";
          };
        };
      }
      ."${moduleContext}";
}

{
  config,
  lib,
  pkgs,
  osConfig ? null,
  moduleContext,
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
    if moduleContext == "home-manager" then
      {
        home.packages = lib.lists.optionals hostinfo.isLaptop [
          pkgs.gnome-power-manager
          pkgs.powerstat
          pkgs.powertop
        ];
      }
    else if moduleContext == "nixos-system" then
      {
        services.logind.settings.Login =
          if hostinfo.isLaptop then
            {
              HandleLidSwitch = "ignore";
              HandleLidSwitchDocked = "ignore";
              HandleLidSwitchExternalPower = "ignore";
            }
          else
            { };
      }
    else
      { };
}

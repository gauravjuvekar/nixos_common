{
  config,
  lib,
  pkgs,
  osConfig ? null,
  moduleContext,
  ...
}:
let
  hostinfo = if (moduleContext == "home-manager") then osConfig.hostinfo else config.hostinfo;
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

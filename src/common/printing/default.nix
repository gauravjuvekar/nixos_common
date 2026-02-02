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
      "home-manager" = lib.mkIf hostinfo.isLaptop {
        home.packages = [
          pkgs.simple-scan
        ];
      };

      "nixos-system" = lib.mkIf hostinfo.isLaptop {
        hardware.sane = {
          enable = true;
          brscan4.enable = true;
          brscan5.enable = true;
        };

        programs.system-config-printer.enable = true;

        services.ipp-usb.enable = true;

        services.printing = {
          enable = true;
          cups-pdf.enable = true;
          drivers = [
            pkgs.brlaser
            pkgs.gutenprint
            pkgs.gutenprintBin
          ];
        };

        users.users."${hostinfo.primaryUsername}".extraGroups = [
          "lp"
          "scanner"
        ];
      };
    }
    ."${moduleContext}";
}

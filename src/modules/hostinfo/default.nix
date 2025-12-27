{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  ...
}:
let
  cfg =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
in
{
  options.hostinfo =
    {
      "home-manager" = { };
      "nixos-system" = {
        isLaptop = lib.mkOption {
          type = lib.types.bool;
          description = "Is laptop?";
        };
        isLocalGraphical = lib.mkOption {
          type = lib.types.bool;
          description = "Has local graphical stack; implies isInteractive and isGrapical";
          default = cfg.isLaptop;
        };
        isLocalInteractive = lib.mkOption {
          type = lib.types.bool;
          description = "Has local interactive terminal (keyboard); implies isInteractive";
          default = cfg.isLocalGraphical;
        };
        isGraphical = lib.mkOption {
          type = lib.types.bool;
          description = "Has remote / local graphical stack; implies isInteractive";
          default = cfg.isLocalGraphical;
        };

        primaryUsername = lib.mkOption {
          type = lib.types.str;
          description = "Default username for home-manager";
        };

        primaryFullname = lib.mkOption {
          type = lib.types.str;
          default = "Gaurav Juvekar";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          description = "Hostname";
        };

        domainname = lib.mkOption {
          type = lib.types.str;
          description = "DNS domain name";
        };

        fqdn = lib.mkOption {
          type = lib.types.str;
          default = "${cfg.hostname}.${cfg.domainname}";
        };
      };
    }
    ."${moduleContext}";
}

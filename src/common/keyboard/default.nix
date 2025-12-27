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
          home.packages = lib.lists.flatten [
            pkgs.dfu-util
            pkgs.keymapviz
            # qmk # Stopped using QMK keyboards for now
            # via # suddenly shows as unfree
            pkgs.wally-cli
            (lib.lists.optional hostinfo.isLocalGraphical pkgs.vial)
          ];
        };

        "nixos-system" = {
          services.keyd = {
            enable = true;
            keyboards = {
              default = {
                ids = [ "*" ];
                settings = {
                  main = {
                    capslock = "overload(control, esc)";
                    esc = "overload(numpad, capslock)";
                    # leftalt = "oneshot(alt)";
                    # leftcontrol = "oneshot(control)";
                    # leftshift = "oneshot(shift)";
                    # meta = "oneshot(meta)";
                    tab = "overload(nav, tab)";
                  };
                  "nav" = {
                    h = "left";
                    j = "down";
                    k = "up";
                    l = "right";
                  };
                  "numpad" = {
                    space = "0";
                    m = "1";
                    "," = "2";
                    "." = "3";
                    j = "4";
                    k = "5";
                    l = "6";
                    u = "7";
                    i = "8";
                    o = "9";
                    "'" = ".";
                    h = "-";
                    ";" = "+";
                    p = "*";
                    y = "*";
                    "/" = "/";
                    n = "/";
                  };
                };
              };
            };
          };
        };
      }
      ."${moduleContext}";
}

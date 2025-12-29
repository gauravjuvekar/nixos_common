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
    lib.mkIf hostinfo.isLocalGraphical
      {
        "home-manager" =
          let
            wayland_gui_allow_root = pkgs.writeShellScriptBin "wayland-gui-allow-root" ''
              ${pkgs.xorg.xhost}/bin/xhost si:localuser:root
            '';
            wayland_gui_forbid_root = pkgs.writeShellScriptBin "wayland-gui-forbid-root" ''
              ${pkgs.xorg.xhost}/bin/xhost -si:localuser:root
            '';
            wayland_screenshot = pkgs.writeShellScriptBin "wayland-screenshot" ''
              ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" - | ${config.programs.satty.package}/bin/satty -f -
            '';
          in
          {
            home.packages = [
              pkgs.shikane
              pkgs.wdisplays
              pkgs.wev
              pkgs.wl-clipboard
              wayland_gui_allow_root
              wayland_gui_forbid_root
              wayland_screenshot
            ];

            xdg.configFile."uwsm/env".text = ''
              export NIXOS_OZONE_WL=1
            '';

            programs.satty = {
              enable = true;
              settings = {
                general = {
                  output-filename = "/home/${config.home.username}/Screenshot-%Y-%m-%d_%H%M%S.png";
                };
                color-palette = {
                  palette = [
                    "#ff00ff"
                    "#f0932b"
                    "#eb4d4d"
                    "#6ab04c"
                    "#22a6b3"
                    "#0000ff"
                    "#ffff00"
                    "#00ffff"
                  ];
                };
              };
            };

            systemd.user.services =
              let
                startupService = (
                  {
                    desc,
                    cmd,
                  }:
                  {
                    Unit = {
                      Description = desc;
                      After = [ "graphical-session.target" ];
                      PartOf = [ "graphical-session.target" ];
                      BindsTo = [ "graphical-session.target" ];
                    };
                    Service = {
                      ExecStart = cmd;
                      Type = "exec";
                    };
                    Install = {
                      WantedBy = [ "graphical-session.target" ];
                    };
                  }
                );
              in
              {
                shikane = startupService {
                  desc = "Wayland display autorandr";
                  cmd = "${pkgs.shikane}/bin/shikane";
                };
                swaync = startupService {
                  desc = "Sway notification center";
                  cmd = "${pkgs.swaynotificationcenter}/bin/swaync";
                };
              };

            programs.hyprlock = {
              enable = true;
              settings = {
                general = {
                  no_fade_in = true;
                  no_fade_out = true;
                };
                background = [
                  {
                    path = "";
                    blur_passes = 3;
                    blur_size = 8;
                  }
                ];
                input-field = [
                  {
                    monitor = "";
                    fade_on_empty = false;
                    fail_text = "($ATTEMPTS) | $FAIL";
                    placeholder_text = "$PAMPROMPT ";
                    size = "500, 50";
                  }
                ];
                label = [
                  {
                    monitor = "";
                    text = "cmd[update:1000] date --rfc-3339 seconds";
                    text_align = "center";
                    font_size = 50;
                    halign = "left";
                    valign = "center";
                    position = "350, 100";
                  }
                  {
                    monitor = "";
                    text = "${hostinfo.primaryFullname} (${config.home.username})<br/>${hostinfo.fqdn}";
                    text_align = "center";
                    halign = "left";
                    valign = "center";
                    font_size = 50;
                    position = "400, -100";
                  }
                ];
              };
            };

            programs.wlogout = {
              enable = true;
              layout = [
                {
                  "label" = "lock";
                  "action" = "${config.programs.hyprlock.package}/bin/hyprlock";
                  "text" = "Lock (l)";
                  "keybind" = "l";
                }
                {
                  "label" = "hibernate";
                  "action" = "systemctl hibernate";
                  "text" = "Hibernate (h)";
                  "keybind" = "h";
                }
                {
                  "label" = "logout";
                  "action" = "${pkgs.niri}/bin/niri msg action quit";
                  "text" = "Logout (e)";
                  "keybind" = "e";
                }
                {
                  "label" = "shutdown";
                  "action" = "systemctl poweroff";
                  "text" = "Shutdown (p)";
                  "keybind" = "p";
                }
                {
                  "label" = "suspend";
                  "action" = "systemctl suspend";
                  "text" = "Suspend (s)";
                  "keybind" = "s";
                }
                {
                  "label" = "reboot";
                  "action" = "systemctl reboot";
                  "text" = "Reboot (r)";
                  "keybind" = "r";
                }
              ];
            };

            services.hypridle = {
              enable = true;
              settings = {
                general = {
                  after_sleep_cmd = "${pkgs.niri}/bin/niri msg action power-on-monitors";
                  before_sleep_cmd = "loginctl lock-session";
                  lock_cmd = "pidof hyprlock || ${config.programs.hyprlock.package}/bin/hyprlock";
                };
                listener = [
                  {
                    timeout = 100;
                    on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
                    on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
                  }
                  {
                    timeout = 300;
                    on-timeout = "${config.programs.hyprlock.package}/bin/hyprlock";
                  }
                  {
                    timeout = 500;
                    on-timeout = "${pkgs.niri}/bin/niri msg action power-off-monitors";
                    on-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
                  }
                ];
              };
            };
          };

        "nixos-system" = {
          security.pam.services = {
            hyprlock = { };
          };
        };
      }
      ."${moduleContext}";
}

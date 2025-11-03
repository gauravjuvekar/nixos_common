{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../wayland.nix
  ];

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
          text = "${config.fullname} (${config.home.username})<br/>${config.fqdn}";
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
        "action" =
          "${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl dispatch exit || ${pkgs.niri}/bin/niri msg action quit";
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
        after_sleep_cmd = "hyprctl dispatch dpms on || ${pkgs.niri}/bin/niri msg action power-on-monitors";
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
          on-timeout = "hyprctl dispatch dpms off || ${pkgs.niri}/bin/niri msg action power-off-monitors";
          on-resume = "hyprctl dispatch dpms on || ${pkgs.niri}/bin/niri msg action power-on-monitors";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$modS" = "SUPER_SHIFT";
      "$modA" = "SUPER_ALT";
      "$modAS" = "SUPER_ALT_SHIFT";
      "$modC" = "SUPER_CTRL";
      "$modCS" = "SUPER_CTRL_SHIFT";
      "$fileManager" = "${pkgs.nemo}/bin/nemo";
      "$logout" = "${config.programs.wlogout.package}/bin/wlogout";
      "$menu" = "${pkgs.fuzzel}/bin/fuzzel";
      "$screenshotTool" = "wayland-screenshot";
      "$terminal" = "${pkgs.alacritty}/bin/alacritty";
      "$volChangeCmd" = "wpctl set-volume @DEFAULT_AUDIO_SINK@";
      "$volMuteCmd" = "wpctl set-mute @DEFAULT_AUDIO_SINK@";
      animation = [
        "global, 1, 2, default"
      ];
      bind = [
        "$mod,  C,     killactive"
        "$mod,  F,     exec,                   $fileManager"
        "$mod,  G,     togglegroup"
        "$mod,  M,     exec,                   $logout"
        "$mod,  N,     changegroupactive,      f"
        "$mod,  P,     changegroupactive,      b"
        "$mod,  Q,     killactive"
        "$mod,  R,     exec,                   $menu"
        "$mod,  S,     togglespecialworkspace"
        "$mod,  SPACE, togglefloating"
        "$mod,  T,     exec,                   $terminal"
        "$modS, N,     movegroupwindow,        f"
        "$modS, P,     movegroupwindow,        b"
        "$modS, R,     exec,                   $screenshotTool"
        "$modS, S,     movetoworkspace,        special"
        ", XF86AudioMute,        exec,         $volMuteCmd toggle"
        ", XF86AudioRaiseVolume, exec,         $volMuteCmd 0"

        "$modAS, H,     movecurrentworkspacetomonitor,  l"
        "$modAS, left,  movecurrentworkspacetomonitor,  l"
        "$modAS, L,     movecurrentworkspacetomonitor,  r"
        "$modAS, right, movecurrentworkspacetomonitor,  r"

        "$modC,  J,     focusworkspaceoncurrentmonitor, r+1"
        "$modC,  down,  focusworkspaceoncurrentmonitor, r+1"
        "$modC,  K,     focusworkspaceoncurrentmonitor, r-1"
        "$modC,  up,    focusworkspaceoncurrentmonitor, r-1"

        "$modC,  L,     focusworkspaceoncurrentmonitor, m+1"
        "$modC,  right, focusworkspaceoncurrentmonitor, m+1"
        "$modC,  H,     focusworkspaceoncurrentmonitor, m-1"
        "$modC,  left,  focusworkspaceoncurrentmonitor, m-1"

        "$modCS, J,     movetoworkspace,                r+1"
        "$modCS, K,     movetoworkspace,                r-1"
      ]
      ++ (builtins.concatLists (
        map
          (
            {
              mod,
              action,
            }:
            [
              "${mod}, left,  ${action}, l"
              "${mod}, H,     ${action}, l"
              "${mod}, down,  ${action}, d"
              "${mod}, J,     ${action}, d"
              "${mod}, up,    ${action}, u"
              "${mod}, K,     ${action}, u"
              "${mod}, right, ${action}, r"
              "${mod}, L,     ${action}, r"
            ]
          )
          [
            {
              mod = "$mod";
              action = "movefocus";
            }
            {
              mod = "$modS";
              action = "movewindoworgroup";
            }
          ]
      ));
      binde = [
        ", XF86AudioRaiseVolume, exec, $volChangeCmd 5%+"
        ", xF86AudioLowerVolume, exec, $volChangeCmd 5%-"
      ];
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      general = {
        border_size = 1;
        gaps_in = 0;
        gaps_out = 0;
        resize_on_border = true;
      };
      misc = {
        force_default_wallpaper = 0;
      };
      xwayland = {
        # Soft blur is better than pixelated
        use_nearest_neighbor = false;
      };
    };
    systemd.enable = false;
    xwayland.enable = true;
  };
}

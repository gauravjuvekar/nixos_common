{ config, pkgs, ... }:
{
  dconf.settings =
    {
      "org/gnome/desktop/interface" =
        {
          "clock-format" = "24h";
          "clock-show-seconds" = true;
        };
      "org/cinnamon/desktop/applications" =
        {
          "terminal/exec" = "alacritty";
        };
      "org/cinnamon/desktop/interface" =
        {
          "clock-show-seconds" = true;
          "clock-use-24h" = true;
          "cursor-theme" = "Vanilla-DMZ";
          "first-day-of-week" = 1;
          "gtk-theme" = "Mint-Y-Dark";
          "icon-theme" = "Mint-X";
        };
      "org/cinnamon/desktop/keybindings" =
        {
          "looking-glass-keybinding" = [];
          "media-keys/home" = [ "<Super>e" "XF86Explorer" "<Super>f"];
          "media-keys/screensaver" =
            [
              "<Control><Alt>l"
              "XF86ScreenSaver"
              "<Super>l"
            ];
          "media-keys/touchpad-toggle" = [ "<Super>F9" "XF86TouchpadToggle" ];
          "wm/switch-to-workspace-1" = [ "<Super>1" ];
          "wm/switch-to-workspace-2" = [ "<Super>2" ];
          "wm/switch-to-workspace-3" = [ "<Super>3" ];
          "wm/switch-to-workspace-4" = [ "<Super>4" ];
          "wm/switch-to-workspace-5" = [ "<Super>5" ];
          "wm/switch-to-workspace-6" = [ "<Super>6" ];
          "wm/switch-to-workspace-7" = [ "<Super>7" ];
          "wm/switch-to-workspace-8" = [ "<Super>8" ];
          "wm/switch-to-workspace-9" = [ "<Super>9" ];
        };
      "org/gnome/libgnomekbd/keyboard" =
        {
          "options" =
            [
              "terminate\tterminate:ctrl_alt_bksp"
            ];
        };
      "org/cinnamon" =
        {
          "desktop-effects-workspace" = false;
          "settings-daemon/plugins/power/lock-on-suspend" = true;
          "workspace-expo-view-as-grid" = true;
          "muffin/workspace-cycle" = true;
        };
      "org/cinnamon/desktop" =
        {
          "media-handling/automount-open" = false;
          "media-handling/autorun-never" = true;
          "screensaver/default-message" =
            config.fullname + " (" + config.home.username + ") " + config.fqdn;
          "screensaver/lock-enabled" = true;
          "screensaver/time-format" = "%H:%M:%S";
          "screensaver/use-custom-format" = true;
          "sound/maximum-volume" = 150;
        };
      "org/cinnamon/desktop/wm/preferences" =
        {
          "action-middle-click-titlebar" = "toggle-shade";
          "action-scroll-titlebar" = "opacity";
          "button-layout" = "menu:minimize,maximize,close";
          "mouse-button-modifier" = "<Super>";
        };
    };
}

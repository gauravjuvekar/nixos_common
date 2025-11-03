{ config, pkgs, ... }:
{
  imports =
    [
      ../wayland.nix
    ];

  home.packages = with pkgs;
    [
     xwayland-satellite
    ];

  systemd.user.services =
    {
      xwayland-satellite =
        {
          Unit =
            {
              Description = "xwayland-satellite bridge for Niri";
              After = [ "niri.service" ];
              BindsTo = [ "niri.service" ];
              PartOf = [ "niri.service" ];
            };
          Service =
            {
              ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :12";
              Type = "exec";
            };
          Install =
            {
              WantedBy = [ "niri.service" ];
            };
        };
    };

  xdg.configFile."niri/config.kdl".text =
    let
      file_manager_path = "${pkgs.nemo}/bin/nemo";
      logout_path = "${config.programs.wlogout.package}/bin/wlogout";
      menu_path =  "${pkgs.fuzzel}/bin/fuzzel";
      terminal_path = "${pkgs.alacritty}/bin/alacritty";
      xwayland_path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
    in
      ''
// This config is in the KDL format: https://kdl.dev
// "/-" comments out the following node.
// Check the wiki for a full description of the configuration:
// https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction

// not yet released
/- xwayland-satellite {
    path "${xwayland_path}"
}

environment {
    DISPLAY ":12"
}

input {
    keyboard {
        numlock
    }

    touchpad {
        tap
        natural-scroll
    }

    warp-mouse-to-focus mode="center-xy"

    focus-follows-mouse max-scroll-amount="1%"
}

layout {
    gaps 0

    center-focused-column "never"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }

    default-column-width { proportion 0.5; }

    focus-ring {
        width 1
        active-color "#ffffff"
        inactive-color "#303030"
        urgent-color "#ff0000"
    }

    border {
        off
    }

    struts {
        left 1
        right 1
        top 0
        bottom 1
    }

    tab-indicator {
        width 15
        place-within-column
        position "top"
        length total-proportion=1.0
    }
}

prefer-no-csd

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

animations {
    off
}

window-rule {
    match app-id=r#"firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

binds {
    Mod+Shift+Slash { show-hotkey-overlay; }
    Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "${terminal_path}"; }
    Mod+R hotkey-overlay-title="Run an Application: fuzzel" { spawn "${menu_path}"; }
    Mod+M hotkey-overlay-title="Lock the Screen: wlogout" { spawn "${logout_path}"; }
    Mod+F hotkey-overlay-title="File manager" { spawn "${file_manager_path}"; }

    Mod+O repeat=false { toggle-overview; }
    Mod+Q { close-window; }

    XF86AudioRaiseVolume allow-when-locked=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
    XF86AudioMute        allow-when-locked=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    XF86AudioMicMute     allow-when-locked=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

    Mod+H     { focus-column-or-monitor-left; }
    Mod+Left  { focus-column-or-monitor-left; }
    Mod+J     { focus-window-or-workspace-down; }
    Mod+Down  { focus-window-or-workspace-down; }
    Mod+K     { focus-window-or-workspace-up; }
    Mod+Up    { focus-window-or-workspace-up; }
    Mod+L     { focus-column-or-monitor-right; }
    Mod+Right { focus-column-or-monitor-right; }

    Mod+U              { focus-workspace-down; }
    Mod+Page_Down      { focus-workspace-down; }
    Mod+I              { focus-workspace-up; }
    Mod+Page_Up        { focus-workspace-up; }

    Mod+Comma  { focus-monitor-left; }
    Mod+Period { focus-monitor-right; }

    Mod+Shift+Comma  { consume-window-into-column; }
    Mod+Shift+Period { expel-window-from-column; }

    Mod+Shift+H     { move-column-left-or-to-monitor-left; }
    Mod+Shift+Left  { move-column-left-or-to-monitor-left; }
    Mod+Shift+J     { move-window-down-or-to-workspace-down; }
    Mod+Shift+Down  { move-window-down-or-to-workspace-down; }
    Mod+Shift+K     { move-window-up-or-to-workspace-up; }
    Mod+Shift+Up    { move-window-up-or-to-workspace-up; }
    Mod+Shift+L     { move-column-right-or-to-monitor-right; }
    Mod+Shift+Right { move-column-right-or-to-monitor-right; }

    Mod+Ctrl+H     { consume-or-expel-window-left;  }
    Mod+Ctrl+Left  { consume-or-expel-window-left;  }
    Mod+Ctrl+L     { consume-or-expel-window-right; }
    Mod+Ctrl+Right { consume-or-expel-window-right; }
    Mod+Ctrl+J     { focus-monitor-left;  }
    Mod+Ctrl+Down  { focus-monitor-left;  }
    Mod+Ctrl+K     { focus-monitor-right; }
    Mod+Ctrl+Up    { focus-monitor-right; }

    Mod+Ctrl+U         { move-column-to-workspace-down; }
    Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
    Mod+Ctrl+I         { move-column-to-workspace-up; }
    Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }

    Mod+Shift+U         { move-workspace-down; }
    Mod+Shift+Page_Down { move-workspace-down; }
    Mod+Shift+I         { move-workspace-up; }
    Mod+Shift+Page_Up   { move-workspace-up; }

    Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
    Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
    Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
    Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

    Mod+WheelScrollRight      { focus-column-right; }
    Mod+WheelScrollLeft       { focus-column-left; }
    Mod+Ctrl+WheelScrollRight { move-column-right; }
    Mod+Ctrl+WheelScrollLeft  { move-column-left; }

    Mod+Shift+WheelScrollDown      { focus-column-right; }
    Mod+Shift+WheelScrollUp        { focus-column-left; }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
    Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    Mod+Ctrl+1 { move-column-to-workspace 1; }
    Mod+Ctrl+2 { move-column-to-workspace 2; }
    Mod+Ctrl+3 { move-column-to-workspace 3; }
    Mod+Ctrl+4 { move-column-to-workspace 4; }
    Mod+Ctrl+5 { move-column-to-workspace 5; }
    Mod+Ctrl+6 { move-column-to-workspace 6; }
    Mod+Ctrl+7 { move-column-to-workspace 7; }
    Mod+Ctrl+8 { move-column-to-workspace 8; }
    Mod+Ctrl+9 { move-column-to-workspace 9; }

    Mod+D { switch-preset-column-width; }
    Mod+Shift+D { switch-preset-window-height; }
    Mod+Ctrl+D { reset-window-height; }
    Mod+Shift+F { fullscreen-window; }

    Mod+S { maximize-column; }
    Mod+Ctrl+F { expand-column-to-available-width; }

    Mod+C { center-column; }
    Mod+Ctrl+C { center-visible-columns; }

    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }

    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }

    Mod+Space       { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }

    Mod+G { toggle-column-tabbed-display; }

    Mod+P { spawn "wayland-screenshot"; }
    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }

    // Applications such as remote-desktop clients and software KVM switches may
    // request that niri stops processing the keyboard shortcuts defined here
    // so they may, for example, forward the key presses as-is to a remote machine.
    // It's a good idea to bind an escape hatch to toggle the inhibitor,
    // so a buggy application can't hold your session hostage.
    //
    // The allow-inhibiting=false property can be applied to other binds as well,
    // which ensures niri always processes them, even when an inhibitor is active.
    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }

    Mod+Shift+P { power-off-monitors; }
}
  '';

  xdg.portal =
    {
      enable = true;
      # started in userspace, so need to be in home-manager config and linked to
      # ~/.nix-profiles/share/xdg-desktop-portal/portals
      # The hyprland home-manager module already does this for us but we don't
      # have a niri module yet.
      extraPortals = with pkgs;
        [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      config =
        {
          niri =
            {
              default = [ "gnome" "gtk" ];
              "org.freedesktop.impl.portal.Access" = "gtk";
              "org.freedesktop.impl.portal.FileChooser" = "gtk";
              "org.freedesktop.impl.portal.Notification" = "gtk";
              "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
            };
        };

    };
}


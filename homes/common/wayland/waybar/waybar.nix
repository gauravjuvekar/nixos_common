{ pkgs, ... }:
let
  mkunicode = s: builtins.fromJSON ("\"\\u" + s + "\"");
in
{
  home.packages = [ pkgs.font-awesome ]; # Required for all the icons
  xdg.configFile."waybar/style.css".text =
    let
      notice-bg-color = "#ecf0f1";
      notice-fg-color = "#333333";
      interactive-bg-color = "#333333";
      interactive-fg-color = "#ffffff";
      urgent-bg-color = "#eb4d4b";
      urgent-fg-color = "#000000";
      bluetooth-blue-bg-color = "#2980b9";
      bluetooth-blue-fg-color = "#000000";
      active-bg-color = "#1ca000";
      active-fg-color = "#000000";
      inactive-bg-color = "#90b1b1";
      inactive-fg-color = "#000000";
    in
    ''
* {
    /* `otf-font-awesome` is required to be installed for icons */
    font-family: Droid Sans Mono Dotted, monospace;
    font-size: 14px;
}

window#waybar {
    background-color: rgba(0, 0, 0, 0.75);
    border-bottom: 1px solid rgba(100, 100, 100, 1);
    color: #ffffff;
}

window#waybar.hidden {
    opacity: 0.2;
}

label {
    padding: 0 5px;
}

label:focus {
    background-color: #000000;
}

button {
    padding: 5px;
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
    border-radius: 0;
}

/* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
button:hover {
    background: rgba(0, 0, 0, 0.2);
    box-shadow: inset 0 3px #ffffff;
}

button.focused {
    background-color: inherit;
    box-shadow: inset 0px -3px #ffffff;
}

button.urgent {
    background-color: ${urgent-bg-color};
    color: ${urgent-fg-color};
}

/* Weird spacing without this */
#taskbar label {
    padding-left: 1px;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#power-profiles-daemon,
#mpd {
    padding: 0 10px;
    color: #ffffff;
}

#window,
#workspaces {
    margin: 0 4px;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background-color: ${interactive-bg-color};
    color: ${interactive-fg-color};
}

#battery {
    background-color: ${notice-bg-color};
    color: ${notice-fg-color};
}

#battery.charging, #battery.plugged {
    background-color: #26A65B;
    color: ${notice-fg-color};
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

/* Using steps() instead of linear as a timing function to limit cpu usage */
#battery.critical:not(.charging) {
    background-color: ${urgent-bg-color};
    color: ${urgent-fg-color};
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#power-profiles-daemon {
    padding-right: 15px;
}

#power-profiles-daemon.performance {
    background-color: #f53c3c;
    color: #ffffff;
}

#power-profiles-daemon.balanced {
    background-color: #2980b9;
    color: #ffffff;
}

#power-profiles-daemon.power-saver {
    background-color: #2ecc71;
    color: #000000;
}

#backlight {
    background-color: ${inactive-bg-color};
    color: ${inactive-fg-color};
}

#network {
    background-color: #2980b9;
}

#network.disconnected {
    background-color: ${urgent-bg-color};
    color: ${urgent-fg-color};
}

#wireplumber,
#pulseaudio {
    background-color: #f1c40f;
    color: #000000;
}

#wireplumber.muted,
#pulseaudio.muted {
    background-color: ${inactive-bg-color};
    color: ${inactive-fg-color};
}

#tray {
    background-color: ${interactive-bg-color};
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: ${urgent-bg-color};
}

#idle_inhibitor {
    background-color: ${interactive-bg-color};
}

#idle_inhibitor.activated {
    background-color: ${notice-bg-color};
    color: ${notice-fg-color};
}

#keyboard-state {
    color: #ffffff;
    min-width: 16px;
}

/* Only highlight the unexpected state */
#keyboard-state > label.numlock:not(.locked),
#keyboard-state > label.capslock.locked,
#keyboard-state > label.scrolllock.locked {
    background-color: ${notice-bg-color};
    color: ${notice-fg-color};
}

#keyboard-state > label:first-child {
    padding-left: 10px;
}

#keyboard-state > label:last-child {
    padding-right: 10px;
}

label#bluetooth.module {
    padding: 0 10px;
}

#bluetooth.on {
    background-color: ${inactive-bg-color};
    color: ${inactive-fg-color};
}

#bluetooth.discoverable {
    background-color: ${bluetooth-blue-bg-color};
    color: ${bluetooth-blue-fg-color};
}

#bluetooth.discovering {
    background-color: ${active-bg-color};
    color: ${active-fg-color};
}

#bluetooth.off,
#bluetooth.disabled,
#bluetooth.no-controller {
    background-color: ${urgent-bg-color};
    color: ${urgent-fg-color};
}

#systemd-failed-units.degraded {
    background-color: ${urgent-bg-color};
    color: ${urgent-fg-color};
}
    '';
  programs.waybar =
    {
      enable = true;
      systemd = { enable = true; };
      settings =
        {
          mainBar =
            {
              layer = "top";
              position = "top";
              height = 32;
              modules-left =
                [
                  "hyprland/workspaces"
                  "niri/workspaces"
                  "wlr/taskbar"
                ];
              modules-center =
                [
                  "hyprland/window"
                  "niri/window"
                ];
              modules-right =
                [
                  "tray"
                  "keyboard-state"
                  "hyprland/submap"
                  "bluetooth"
                  "wireplumber"
                  "clock"
                  "idle_inhibitor"
                  "systemd-failed-units"
                ];

              "niri/workspaces" =
                {
                  all-outputs = false;
                };

              "hyprland/workspaces" =
                {
                  disable-scroll = true;
                  all-outputs = false;
                  show-special = true;
                  special-visible-only = true;
                };

              "hyprland/window" =
                {
                  separate-outputs = true;
                };

              "niri/window" =
                {
                  separate-outputs = true;
                };

              keyboard-state =
                {
                  numlock = true;
                  capslock = true;
                  scrolllock = true;
                  format =
                    let
                      pango_space_hack = "<span font-family=\"Roboto\">" + (mkunicode "2006") + "{icon}</span>";
                    in
                    {
                      numlock = "N" + pango_space_hack;
                      capslock = "C" + pango_space_hack;
                      scrolllock = "S" + pango_space_hack;
                    };
                  format-icons =
                    {
                      locked = mkunicode "f023"; # lock
                      unlocked = mkunicode "2007"; # figure-space
                    };
                };

              "wlr/taskbar" =
                {
                  on-click = "activate";
                  on-click-middle = "close";
                };

              tray =
                {
                  spacing = 10;
                };

              bluetooth =
                {
                  format-connected = (mkunicode "f294") + " {num_connections} con"; # bluetooth-symbol
                  format-disabled = (mkunicode "f294") + " rfkill"; # bluetooth-symbol
                  format-off = (mkunicode "f294") + " off"; # bluetooth-symbol
                  tooltip-format = "{controller_alias}  {controller_address}";
                  tooltip-format-connected = "{controller_alias}  {controller_address}\n\n{device_enumerate}";
                  tooltip-format-enumerate-connected = "{device_address}  {device_alias}";
                  tooltip-format-enumerate-connected-battery = "{device_address} " + (mkunicode "f0e7") + " {device_battery_percentage:3}%  {device_alias}"; # bolt
                  on-click = "${pkgs.blueberry}/bin/blueberry";
                  on-click-right = "${pkgs.blueman}/bin/blueman-manager";
                  on-click-middle = pkgs.writeShellScript "bluetooth-toggle"
                    (
                      let
                        bluetoothctl-bin = "${pkgs.bluez}/bin/bluetoothctl";
                      in
                      ''
                      ${bluetoothctl-bin} power $(${bluetoothctl-bin} show | grep -q "Powered: yes" && echo off || echo on)

                      ''
                    );
                };

              idle_inhibitor =
                {
                  format = "{icon}";
                  format-icons =
                    {
                      activated = mkunicode "f0f4"; # icon-coffee
                      deactivated = mkunicode "f186"; # icon-moon
                    };
                };

              wireplumber =
                {
                  on-click = "${pkgs.cinnamon-common}/bin/cinnamon-settings sound";
                  on-click-middle = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                  format = (mkunicode "f028") + " {volume:3}%"; # volume-high
                  format-muted = (mkunicode "f026") + (mkunicode "f00d") + "{volume:3}%"; # volume-off xmark
                };

              clock =
                {
                  interval = 1;
                  format = "{:%a %F %T%z %Z}";
                  tooltip-format =
                    "<tt>{tz_list}</tt>" +
                    "\n" +
                    "<tt>{calendar}</tt>";
                  timezones =
                    [
                      "America/Los_Angeles"
                      "Asia/Kolkata"
                      "America/New_York"
                      "Asia/Taipei"
                      "Etc/UTC"
                    ];
                  actions =
                    {
                      on-click-right = "mode";
                      on-scroll-up = "tz_up";
                      on-scroll-down = "tz_down";
                    };
                  calendar =
                    {
                      mode = "year";
                      mode-mon-col = 3;
                      week-pos = "left";
                      on-scroll = 1;
                    };
                };
            };
        };
    };
}

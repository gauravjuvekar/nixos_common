{ pkgs, ... }:
let
  gtkTheme = "Mint-Y-Dark";
in
{
  imports = [
    ./alacritty/alacritty.nix
    ./audio/audio_graphical.nix
    ./cinnamon/cinnamon.nix
    ./graphical_xdg.nix
    ./keyboards/keyboards_graphical.nix
    ./nemo/nemo.nix
    ./wayland/hyprland/hyprland.nix
    ./wayland/niri/niri.nix
  ];

  home.packages = with pkgs; [
    arandr
    baobab
    blueberry
    dconf-editor
    (flameshot.overrideAttrs { enableWlrSupport = true; })
    gnome-font-viewer
    gnome-system-monitor
    imhex
    screenkey
    seahorse
    shutter
    wmctrl
    xclip
    xorg.xkill
  ];

  gtk.theme = gtkTheme;
  home.sessionVariables = {
    GTK_THEME = gtkTheme;
  };
}

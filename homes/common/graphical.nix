{ pkgs, ... }:
let
  gtkTheme = "Mint-Y-Dark";
in
{
  imports = [
    ./alacritty/alacritty.nix
    ./graphical_xdg.nix
  ];

  home.packages = with pkgs; [
    arandr
    baobab
    blueberry
    dconf-editor
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

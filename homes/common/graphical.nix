{ pkgs, ... }:
let
  gtkTheme = "Mint-Y-Dark";
in
{
  imports = [
    ./graphical_xdg.nix
  ];

  home.packages = with pkgs; [
    baobab
    blueberry
    gnome-font-viewer
    gnome-system-monitor
    screenkey
    seahorse
    shutter
  ];

  gtk.theme = gtkTheme;
  home.sessionVariables = {
    GTK_THEME = gtkTheme;
  };
}

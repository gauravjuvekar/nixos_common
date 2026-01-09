{ pkgs, ... }:
let
  gtkTheme = "Mint-Y-Dark";
in
{
  home.packages = with pkgs; [
    baobab
    blueberry
    gnome-system-monitor
    screenkey
    shutter
  ];

  gtk.theme = gtkTheme;
  home.sessionVariables = {
    GTK_THEME = gtkTheme;
  };
}

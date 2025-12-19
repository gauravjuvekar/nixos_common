{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnome-power-manager
  ];
}

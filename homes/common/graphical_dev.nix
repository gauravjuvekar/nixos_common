{ pkgs, ... }:
{
  home.packages = with pkgs; [
    graphviz
    neovide
    plantuml
  ];
}

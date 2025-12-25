{ pkgs, ... }:
{
  home.packages = with pkgs; [
    graphviz
    meld
    neovide
    plantuml
  ];
}

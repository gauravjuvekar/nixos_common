{ pkgs, ... }:
{
  home.packages = with pkgs; [
    graphviz
    imhex
    meld
    neovide
    plantuml
    sqlitebrowser
  ];
}

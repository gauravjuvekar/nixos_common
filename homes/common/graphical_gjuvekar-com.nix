{ pkgs, ... }:
{
  imports = [
    ./gnucash/gnucash.nix
    ./picard/picard.nix
  ];
  home.packages = with pkgs; [
    clementine
    kid3-qt
    python3Packages.eyed3
  ];
}

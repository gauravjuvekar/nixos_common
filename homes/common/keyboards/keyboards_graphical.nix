{ pkgs, ... }:
{
  home.packages = with pkgs;
    [
      # keymap # ZSA proprietary
      vial
    ];
}

{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dfu-util
    keymapviz
    # qmk # Stopped using QMK keyboards for now
    # via # suddenly shows as unfree
    wally-cli
  ];
}

{ pkgs, ... }:
{
  hardware.keyboard.qmk.enable = true;
  hardware.keyboard.zsa.enable = true;
  services.udev.packages = [
    pkgs.via
  ];
}

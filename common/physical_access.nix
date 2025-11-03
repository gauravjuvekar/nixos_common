{ pkgs, ... }:
{
  imports = [
    ./physical_access_yubikey.nix
  ];

  environment.systemPackages = with pkgs; [
    lm_sensors
    lshw
    pciutils
    usbutils
  ];
}

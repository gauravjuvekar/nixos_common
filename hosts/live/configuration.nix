{ config, pkgs, ... }:
{
  imports =
    [
      ../../common/base_etc.nix
    ];

  systemd.services."xe-daemon".enable = false;

  boot.kernelModules = [ "dm-raid" "dm-integrity" ];
}

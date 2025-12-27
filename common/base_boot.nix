{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      copyKernels = true;
      device = "nodev";
      efiSupport = true;
      enableCryptodisk = true;
    };
    timeout = 10;
  };

  boot.initrd = {
    kernelModules = [
      "dm-snapshot"
      "dm-integrity"
      "dm-raid"
    ];
    supportedFilesystems = [
      "btrfs"
      "ext4"
      "vfat"
    ];
    systemd = {
      enable = true;
      emergencyAccess = true;
      settings.Manager = {
        DefaultDeviceTimeoutSec = 20;
        StatusUnitFormat = "name";
      };
    };
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  boot.swraid.enable = true;
}

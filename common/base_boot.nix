{ config, pkgs, lib, ... }:
{
  boot.loader =
    {
      efi.canTouchEfiVariables = true;
      grub =
        {
          enable = true;
          copyKernels = true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = true;
        };
      timeout=10;
    };

  boot.initrd = {
      kernelModules = [ "dm-snapshot" "dm-integrity" "dm-raid" ];
      services =
        {
          lvm.enable = true;
          udev =
            {
              rules = config.services.udev.extraRules;
              packages =
                [
                  (pkgs.writeTextFile {
                    name = "my-lvm-initrd-udev-rules";
                    destination = "/etc/udev/rules.d/10-local.rules";
                    text = config.boot.initrd.services.udev.rules;
                  })
                ];
            };
        };
      supportedFilesystems = [ "btrfs" "ext4" "vfat" ];
      systemd =
        {
          enable = true;
          emergencyAccess = true;
          services =
            {
              # Bug https://github.com/NixOS/nixpkgs/issues/428775
              "systemd-udevd".after = [ "systemd-modules-load.service" ];
            };
          settings.Manager =
            {
              DefaultDeviceTimeoutSec = 20;
              StatusUnitFormat = "name";
            };
          contents =
            {
              "/etc/lvm/lvm.conf".source = ./files/lvm.conf;
            };
        };
    };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_15;

  boot.swraid.enable = true;
}

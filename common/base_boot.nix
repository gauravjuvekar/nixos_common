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

  boot.initrd =
    {
      kernelModules = [ "dm-snapshot" "dm-integrity" "dm-raid" ];
      services.lvm.enable = true;
      supportedFilesystems = [ "btrfs" "ext4" "vfat" ];
      systemd =
        {
          enable = true;
          contents =
            {
              "/etc/lvm/lvm.conf".source = ./files/lvm.conf;
            };
        };
    };

  boot.swraid.enable = true;
}

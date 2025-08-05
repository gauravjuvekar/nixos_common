{ config, lib, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.loader.grub.useOSProber = false;
  boot.loader.grub.extraGrubInstallArgs =
    [
      "--modules=nativedisk part_gpt diskfilter lvm mdraid1x"
    ];
  boot.loader.grub.extraEntries = ''
    menuentry Windows {
      insmod part_gpt
      insmod fat
      insmod search_fs_uuid
      insmod chain
      search --fs-uuid --set=root 6FA7-FA84
      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
    '';

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "nvme" ];
  boot.initrd.kernelModules = [ "nvidia" "dm_crypt" "raid1" ];

  # Bug https://github.com/NixOS/nixpkgs/issues/428775
  boot.initrd.systemd.services."lvm-activate-vgRaid1Disks3.service".after = [ "systemd-modules-load.service" ];

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ config.hardware.nvidia.package ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/e8c01229-6f85-482c-a89c-5a15f7b9892b";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2a4b3410-ef8a-4d29-9adf-d9a01e3ac495";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."main_os_crypt".device =
    "/dev/disk/by-uuid/cd0dbc3d-7458-4d11-8a00-f9ea61baaea8";

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/6FA7-FA84";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/e8c01229-6f85-482c-a89c-5a15f7b9892b";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/var/log" =
    { device = "/dev/disk/by-uuid/e8c01229-6f85-482c-a89c-5a15f7b9892b";
      fsType = "btrfs";
      options = [ "subvol=@var-log" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/fad5a2a6-de92-4458-a335-55d182b087b9";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/home/.snapshots" =
    { device = "/dev/disk/by-uuid/fad5a2a6-de92-4458-a335-55d182b087b9";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" ];
    };

  environment.etc."crypttab".text = ''
      main_boot_crypt UUID=2d47987a-cf3d-4693-bb18-d0c8312d2924 /root/boot.key
    '';

  swapDevices =
    [ { device = "/dev/disk/by-uuid/e0358e18-7b60-4ea6-8d91-de0780b82e46"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}

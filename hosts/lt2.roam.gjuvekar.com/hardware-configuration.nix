{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.loader.grub.extraGrubInstallArgs = [
#    "--verbose"
    "--modules=nativedisk part_gpt diskfilter lvm mdraid1x"
  ];

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "nvme" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/e5ab684c-b3f9-43ff-8722-d342bb53d785";
      fsType = "btrfs";
      encrypted =
        {
          enable = true;
          blkDev = "/dev/disk/by-uuid/3c8a2fcc-c3ce-400f-8b66-d8d439c6b715";
          label  = "nix_crypt";
        };
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/5db87037-e2d9-40a4-a9f3-9a0dc052c528";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/B050-F67C";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/33f01d32-5aed-4ebf-8a59-f92c9d20a9df";
      fsType = "btrfs";
      options = [ "subvol=@" ];
      encrypted =
        {
          enable = true;
          blkDev = "/dev/disk/by-uuid/0664ad23-f2e6-498f-8f6c-58efcc64bfef";
          label  = "arch_crypt";
          keyFile = "/sysroot/root/home.key";
        };
    };

  fileSystems."/home/.snapshots" =
    { device = "/dev/disk/by-uuid/33f01d32-5aed-4ebf-8a59-f92c9d20a9df";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" ];
    };

  environment.etc."crypttab".text = ''
      arch_crypt UUID=0664ad23-f2e6-498f-8f6c-58efcc64bfef /root/home.key
    '';

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

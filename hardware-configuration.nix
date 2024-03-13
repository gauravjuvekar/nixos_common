# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;
  boot.loader.grub.extraGrubInstallArgs = [
#    "--verbose"
    "--modules=nativedisk part_gpt diskfilter lvm mdraid1x"
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "nvme" ];
  boot.initrd.supportedFilesystems = [ "btrfs" "ext4" "vfat" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "dm-integrity" "dm-raid" ];
  boot.initrd.systemd.enable = true;
  boot.initrd.services.lvm.enable = true;
  boot.swraid.enable = true;
  boot.initrd.systemd.contents =
    {
      "/etc/lvm/lvm.conf".source = ./files/lvm.conf;
    };
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

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

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s20f0u1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

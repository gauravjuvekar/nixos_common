{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # This Pi 4 already boots via UEFI and GRUB, not the NixOS SD-image loader.
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 10;
  };
  boot.loader.efi = {
    canTouchEfiVariables = false;
    efiSysMountPoint = "/boot/esp";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [
    "vc4"
    "bcm2835_dma"
    "i2c_bcm2835"
    "usb_storage"
    "xhci_pci"
    "uas"
    "usbhid"
    "sd_mod"
    # SD key device, including the ACPI/UEFI SDHCI path.
    "sdhci"
    "sdhci_pci"
    "sdhci_acpi"
    "sdhci_iproc"
    "sdhci_pltfm"
    "mmc_block"
    # Wired recovery networking on this Pi 4.
    "genet"
    "broadcom"
  ];
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "dm-integrity"
    "dm-raid"
  ];
  boot.initrd.systemd.enable = true;
  boot.initrd.services.lvm.enable = true;
  boot.initrd.systemd.contents."/etc/lvm/lvm.conf".source = ./files/lvm.conf;
  # Scan LVs as well as partitions: base/crypt -> LUKS -> nix_vg.
  environment.etc."lvm/lvm.conf".text = lib.mkAfter ''
    devices {
      scan_lvs = 1
    }
  '';
  boot.supportedFilesystems = [ "btrfs" ];

  # The LV exists, but swap is disabled in the running configuration.
  swapDevices = lib.mkForce [ ];
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}

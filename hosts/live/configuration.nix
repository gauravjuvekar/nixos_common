{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../common/age.nix
    ../../common/base_etc.nix
    ../../common/base_packages.nix
  ];

  networking.hostName = "live";
  networking.domain = "localdomain";

  nixpkgs.config.allowUnfree = true;

  systemd.services."xe-daemon".enable = false;

  boot.kernelModules = [
    "btrfs"
    "dm-integrity"
    "dm-raid"
    "dm-snapshot"
    "exfat"
    "ext4"
    "vfat"
  ];

  environment.systemPackages = with pkgs; [
    cloudflare-warp
  ];
}

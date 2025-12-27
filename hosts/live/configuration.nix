{ pkgs, ... }:
{
  imports = [
    ../../common/age.nix
    ../../common/base_packages.nix
  ];

  networking.hostName = "live";
  networking.domain = "localdomain";

  nixpkgs.config.allowUnfree = true;

  systemd.services."xe-daemon".enable = false;
  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "8.8.8.8#dns.google"
    "2606:4700:4700::1111#cloudflare-dns.com"
    "2001:4860:4860::8888#dns.google"
  ];

  services.resolved = {
    enable = true;
    dnsovertls = "true";
  };

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
    smplayer
    vlc
  ];
}

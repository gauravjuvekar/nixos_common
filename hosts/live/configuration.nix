{ pkgs, lib, ... }:
{
  imports =
    [
      ../../common/age.nix
      ../../common/base_etc.nix
      ../../common/base_packages.nix
    ];

  networking.hostName = "live";
  networking.domain = "localdomain";

  nixpkgs.config.allowUnfree = true;

  systemd.services."xe-daemon".enable = false;

  boot.kernelModules = [ "dm-raid" "dm-integrity" ];

  environment.systemPackages = with pkgs;
    [
      cloudflare-warp
    ];
}

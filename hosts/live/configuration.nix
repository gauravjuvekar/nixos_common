{ pkgs, ... }:
{
  imports =
    [
      ../../common/base_etc.nix
      ../../common/base_packages.nix
    ];

  nixpkgs.config.allowUnfree = true;

  systemd.services."xe-daemon".enable = false;

  boot.kernelModules = [ "dm-raid" "dm-integrity" ];

  environment.systemPackages = with pkgs;
    [
      cloudflare-warp
    ];
}

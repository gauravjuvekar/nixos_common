{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common/base.nix
      ../../common/graphical.nix
      ../../common/interactive.nix
      ../../common/physical_access.nix
      ../../common/user_personal.nix
      ./snapper.nix
    ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "gaurav-nixlt";
  networking.domain = "roam.gjuvekar.com";

  time.timeZone = "America/Los_Angeles";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;

  programs.gnupg.agent =
    {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

  services.gnome.gnome-keyring.enable = true;

  networking.firewall.enable = false;

  system.copySystemConfiguration = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
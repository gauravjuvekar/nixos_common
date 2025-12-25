{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/age.nix
    ../../common/base.nix
    ../../common/base_personal.nix
    ../../common/graphical.nix
    ../../common/interactive.nix
    ../../common/networking_open_wifi.nix
    ../../common/physical_access.nix
    ../../common/user_personal.nix
    ./snapper.nix
  ];

  nixpkgs.config.allowUnfree = true;
  networking.hostName = "dt";
  networking.domain = "sc.gjuvekar.com";

  hostinfo.isLaptop = false;
  hostinfo.isLocalGraphical = true;
  usageinfo = {
    devLangs = [
      "cxx"
      "python"
      "rust"
    ];
    devTools = [
      "containers"
      "perf"
    ];
    cadTools = [
      "2d"
      "3d"
      "eda"
      "gis"
    ];
  };

  time.timeZone = "America/Los_Angeles";

  services.xserver.videoDrivers = [ "nvidia" ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_17;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  services.gnome.gnome-keyring.enable = true;

  system.copySystemConfiguration = false;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBmEgqsCVOhdqv9mChSwFjqdMBOS4K4ojkGH6AcH+8Nh root@dt";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

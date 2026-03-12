{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./snapper.nix
  ];

  nixpkgs.config.allowUnfree = true;
  networking.hostName = "dt";
  networking.domain = "sc.gjuvekar.com";

  hostinfo = {
    isLaptop = false;
    isLocalGraphical = true;
    hostname = "dt";
    domainname = "sc.gjuvekar.com";
    primaryUsername = "gaurav";
  };

  usageinfo = {
    devLangs = [
      "cxx"
      "python"
      "rust"
    ];
    devTools = [
      "binary"
      "containers"
      "db"
      "memory"
      "network"
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
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_18;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version            = "580.142";
      sha256_64bit       = "sha256-IJFfzz/+icNVDPk7YKBKKFRTFQ2S4kaOGRGkNiBEdWM=";
      openSha256         = "sha256-v968LbRqy8jB9+yHy9ceP2TDdgyqfDQ6P41NsCoM2AY=";
      settingsSha256     = "sha256-BnrIlj5AvXTfqg/qcBt2OS9bTDDZd3uhf5jqOtTMTQM=";
      persistencedSha256 = "sha256-0000000000000000000000000000000000000000000=";
    };
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

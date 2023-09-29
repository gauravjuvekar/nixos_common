# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.extraOptions = ''
    extra-experimental-features = nix-command
  '';

  networking.hostName = "gaurav-nixlt";
  networking.networkmanager.enable = true; 

  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Cinnamon Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;


  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gaurav = 
    {
      isNormalUser = true;
      home = "/home/gaurav";
      uid = 1001;
      extraGroups =
        [
          "networkmanager"
          "wheel"
        ];
    };

  users.groups.gaurav.gid = 1001;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [
      alacritty
      arandr
      autojump
      baobab
      barrier
      bindfs
      bless
      chromium
      clang
      clang-tools
      du-dust
      easyeffects
      evolution
      fd
      firefox
      fzf
      galculator
      gcc
      gdb
      gh
      gimp
      git
      gnome.eog
      gnome.gnome-calculator
      gnome.gnome-disk-utility
      gnome.gnome-keyring
      gnome.gnome-system-monitor
      gnome.gnome-terminal
      gnome.seahorse
      gnucash
      gparted
      helvum
      htop
      inkscape
      inotify-tools
      inxi
      iperf
      jq
      kicad
      libreoffice
      lldb
      meld
      mpv
      netcat-openbsd
      nvme-cli
      obs-studio
      parallel
      pass
      pavucontrol
      pdfarranger
      pdftk
      pipewire
      qpdf
      qpwgraph
      ripgrep
      rustc
      rustfmt
      screen
      screenkey
      shutter
      silver-searcher
      smartmontools
      socat
      sqlite
      sqlitebrowser
      thunderbird
      tree
      unixODBCDrivers.sqlite
      valgrind
      vim
      vlc
      websocat
      wget
      xclip
      xorg.xkill
      yq
      yubikey-manager
      yubikey-manager-qt
      yubikey-personalization
      yubikey-personalization-gui
    ];

  # nano is horror
  programs.neovim =
    {
      defaultEditor = true;
      enable = true;
    };

  environment.etc =
    {
      "lvm/lvm.conf" = lib.mkForce 
        { 
          source = ./files/lvm.conf; 
          mode = "0600";
        }; 
    };

  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}


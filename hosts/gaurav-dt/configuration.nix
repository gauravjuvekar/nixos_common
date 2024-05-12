{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common/base.nix
      ../../common/interactive.nix
      ../../common/user_personal.nix
    ];

  nixpkgs.config.allowUnfree = true;
  networking.hostName = "gaurav-dt";

  time.timeZone = "America/Los_Angeles";

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia =
  {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.opengl.enable = true;

  services.xserver.displayManager.gdm.enable = false;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal];
  programs.hyprland.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.libinput.enable = true;

  programs.gnupg.agent =
    {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs;
    [
#      age
      alacritty
      arandr
#      autojump
#      baobab
#      barrier
      bindfs
#      bless
#      blueberry
#      chromium
#      clang
#      clang-tools
#      dig
#      drill
#      du-dust
#      easyeffects
      firefox
#      flameshot
#      fzf
#      galculator
#      gcc
#      gdb
#      gh
#      ghostscript
#      gimp
#      gnome.eog
#      gnome.gnome-calculator
#      gnome.gnome-disk-utility
#      gnome.gnome-keyring
#      gnome.gnome-system-monitor
#      gnome.gnome-terminal
#      gnome.seahorse
#     gnucash
      gparted
#      helvum
      htop
#      imagemagick
#      inetutils
#      inkscape
#      inotify-tools
#      inxi
#      iperf
#      jq
#      libreoffice
#      lldb
#      meld
#      mpv
#      netcat-openbsd
#      nvme-cli
#      obs-studio
#      pass
#      pavucontrol
#      pdfarranger
#      pdftk
#      pipewire
#      qpdf
#      qpwgraph
#      rustc
#      rustfmt
#      screenkey
#      shutter
#      smartmontools
#      snapper
#      snapper-gui
#      socat
#      sqlite
#      sqlitebrowser
#      syncthing
#      thunderbird
#      unixODBCDrivers.sqlite
#      valgrind
#      vim
#      vlc
#      websocat
#      wireshark
      xclip
      xorg.xkill
#      yq
#      yubikey-manager
#      yubikey-manager-qt
#      yubikey-personalization
#      yubikey-personalization-gui
    ];

  networking.firewall.enable = false;

  system.copySystemConfiguration = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

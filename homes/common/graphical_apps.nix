{ pkgs, ... }:
{
  imports = [
    ./firefox/firefox.nix
  ];

  home.packages = with pkgs; [
    chromium
    digikam
    libreoffice
    mpv
    obs-studio
    # openshot-qt # qtwebengine-5.15.19 is insecure
    qalculate-gtk
    remmina
    smplayer
    thunderbird
    vlc
  ];
}

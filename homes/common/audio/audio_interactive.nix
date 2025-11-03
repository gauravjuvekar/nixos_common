{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pipewire
    pulseaudio
    wireplumber
  ];
}

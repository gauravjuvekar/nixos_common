{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chromaprint
    picard
  ];
  xdg.configFile."MusicBrainz/Picard.ini".source = ./Picard.ini;
}

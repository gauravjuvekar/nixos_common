{ pkgs, ... }:
{
  home.packages = with pkgs; [
    yubioath-flutter
  ];
}

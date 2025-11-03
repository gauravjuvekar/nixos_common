{ pkgs, ... }:
{
  home.packages = with pkgs; [
    screen
  ];

  home.file = {
    ".screenrc".text = ''
      escape ^Jj
    '';
  };
}

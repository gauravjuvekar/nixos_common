{ pkgs, ... }:
{
  programs.gpg =
    {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
    };
  services.gpg-agent =
    {
      enable = true;
      enableBashIntegration = true;
      extraConfig =
        ''
          pinentry-program ${pkgs.pinentry-curses}/bin/pinentry
        '';
    };
  home.packages = with pkgs;
    [
      gnupg
      pinentry-curses
    ];
}

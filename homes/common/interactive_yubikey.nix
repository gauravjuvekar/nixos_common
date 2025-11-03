{ pkgs, ... }:
{
  home.packages = with pkgs;
    [
      age-plugin-yubikey
      libfido2
      yubikey-manager
    ];
  programs.gpg =
    {
      scdaemonSettings =
        {
          disable-ccid = true;
          reader-port = "Yubico Yubi";
        };
    };
}

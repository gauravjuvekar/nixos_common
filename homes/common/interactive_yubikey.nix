{ ... }:
{
  programs.gpg = {
    scdaemonSettings = {
      disable-ccid = true;
      reader-port = "Yubico Yubi";
    };
  };
}

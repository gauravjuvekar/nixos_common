{ ... }:
{
  security = {
    polkit.enable = true;
  };

  services.pcscd.enable = true;
}

{ ... }:
{
  programs.firefox.profiles."Personal" = {
    isDefault = true;
    settings."network.trr.mode" = 3;
  };
}

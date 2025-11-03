{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pwvucontrol
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.support32Bit = true;
    alsa.enable = true;
    pulse.enable = true;
    extraLv2Packages = [ pkgs.lsp-plugins ];
    wireplumber = {
      enable = true;
      extraLv2Packages = [ pkgs.lsp-plugins ];
    };
  };
  services.pulseaudio.enable = false;
}

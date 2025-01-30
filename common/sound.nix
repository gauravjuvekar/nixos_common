{ pkgs, ... }:
{
  environment.systemPackages = with pkgs;
    [
      pavucontrol
    ];

  security.rtkit.enable = true;
  services.pipewire =
    {
      enable = true;
      alsa.support32Bit = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  services.pulseaudio.enable = false;
}

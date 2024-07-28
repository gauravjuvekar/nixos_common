{ pkgs, ... }:
{
  environment.systemPackages = with pkgs;
    [
      pavucontrol
    ];

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire =
    {
      enable = true;
      alsa.support32Bit = true;
      alsa.enable = true;
      pulse.enable = true;
    };
}

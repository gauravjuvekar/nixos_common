{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    pam_u2f
  ];

  security = {
    polkit.enable = true;
    pam = {
      services."sudo".u2fAuth = true;
      u2f.settings = {
        cue = true;
        origin = "pam://${config.networking.fqdn}";
      };
    };
  };

  services.pcscd.enable = true;
}

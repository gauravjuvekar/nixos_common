{
  config,
  ...
}:
{
  security = {
    polkit.enable = true;
    pam = {
      services."sudo".u2fAuth = true;
      u2f.settings = {
        authfile = "/home/%u/.config/pam_sudo/pam_u2f_authorized_keys";
        cue = true;
        expand = true;
        origin = "pam://${config.networking.fqdn}";
      };
    };
  };

  services.pcscd.enable = true;
}

{
  config,
  lib,
  moduleContext,
  ...
}:
{
  config =
    {
      "home-manager" = { };
      "nixos-system" = {
        # Also enables fingerprint authentication in the default PAM stacks and GDM.
        services.fprintd.enable = lib.mkIf config.hostinfo.isLaptop true;

        # Keep password authentication available alongside fingerprint login.
        security.pam.services = lib.mkIf config.hostinfo.isLaptop {
          login.unixAuth = true;
          sudo.unixAuth = true;
        };
      };
    }
    ."${moduleContext}";
}

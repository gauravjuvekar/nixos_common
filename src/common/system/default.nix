{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  ...
}:
let
  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
in
{
  config =
    let
      sys_and_user_config = {
        Manager.StatusUnitFormat = "combined";
      };
    in
    {
      "home-manager" = {
        systemd.user.settings = sys_and_user_config;
      };

      "nixos-system" = {
        boot.kernel.sysctl = lib.mkIf hostinfo.isLocalInteractive {
          "kernel.sysrq" = 1;
        };

        systemd.settings = sys_and_user_config;
      };
    }
    ."${moduleContext}";
}

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
    {
      "home-manager" = { };
      "nixos-system" = {
        programs.wireshark = {
          enable = hostinfo.isLocalGraphical;
          dumpcap.enable = true;
          usbmon.enable = true;
        };

        users.users = lib.mkIf (hostinfo.primaryUsername != null && config.programs.wireshark.enable) {
          "${hostinfo.primaryUsername}".extraGroups = [ "wireshark" ];
        };
      };
    }
    ."${moduleContext}";
}

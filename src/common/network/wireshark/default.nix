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

        users.users."${hostinfo.primaryUsername}".extraGroups = lib.lists.flatten [
          (lib.lists.optional config.programs.wireshark.enable "wireshark")
        ];
      };
    }
    ."${moduleContext}";
}

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
      "home-manager" = {
      };

      "nixos-system" = {
        networking = {
          hostName = hostinfo.hostname;
          domain = hostinfo.domainname;
        };
      };
    }
    ."${moduleContext}";
}

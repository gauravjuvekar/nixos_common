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
      domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
    in
    {
      "home-manager" = { };
      "nixos-system" = lib.mkIf domain_is_personal {
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          nssmdns6 = true;
          openFirewall = true;
          settings.publish = lib.mkIf (hostinfo.domainname == "sc.gjuvekar.com") {
            disable-publishing = false;
            publish-addresses = true;
          };
        };
      };
    }
    ."${moduleContext}";
}

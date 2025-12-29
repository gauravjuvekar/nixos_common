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

      "nixos-system" =
        let
          domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
        in
        {
          users.users."${hostinfo.primaryUsername}" = {
            description = hostinfo.primaryFullname;
            isNormalUser = true;
            home = "/home/${hostinfo.primaryUsername}";
            hashedPasswordFile = if domain_is_personal then config.age.secrets.user-passwd.path else null;
            uid = if domain_is_personal then 1001 else null;
            extraGroups = [
              "wheel"
            ];
          };
          users.groups."${hostinfo.primaryUsername}".gid = if domain_is_personal then 1001 else null;

          age.secrets = lib.mkIf domain_is_personal {
            user-passwd.rekeyFile = ../../../keys/secrets/gaurav-passwd.age;
          };
        };
    }
    ."${moduleContext}";
}

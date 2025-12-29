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
        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.rekey = {
          masterIdentities = [
            {
              # Only required for re-keying secrets, so absolute paths are okay
              # for now as this will only be done on ".gjuvekar.com" hosts.
              identity = "/home/gaurav/.ssh/age-master-key.age";
              pubkey = "age1ewckdchd9lj9dghe4v2apvqa84vpnp5xkru6mpf63sc9n3mr6qpqdnvwum";
            }
          ];
          localStorageDir = ../../../. + "/keys/secrets/rekeyed/${config.networking.fqdn}";
          storageMode = "local";
        };
      };
    }
    ."${moduleContext}";
}

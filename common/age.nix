{ config, ... }:
{
  age.rekey =
    {
      masterIdentities =
        [
          {
            identity = "/home/gaurav/.ssh/age-master-key.age";
            pubkey = "age1ewckdchd9lj9dghe4v2apvqa84vpnp5xkru6mpf63sc9n3mr6qpqdnvwum";
          }
        ];
      localStorageDir = ../. + "/keys/secrets/rekeyed/${config.networking.fqdn}";
      storageMode = "local";
    };
}

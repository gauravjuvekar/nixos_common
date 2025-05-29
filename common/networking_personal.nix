{ pkgs, ... }:
{
  services.openssh.extraConfig =
    let
      trusted_ca_keys = pkgs.concatTextFile
        {
          name = "sshd-ca-keys";
          files =
            [
              ../keys/yk5a-22897261-ssh-signing-key.pub
              ../keys/yk5c-24251755-ssh-signing-key.pub
            ];
          destination = "/ssh_trusted_ca_keys";

        };
    in
    ''
      TrustedUserCAKeys ${trusted_ca_keys}/ssh_trusted_ca_keys
    '';
}

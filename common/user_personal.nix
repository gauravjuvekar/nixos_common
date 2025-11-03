{ config, ... }:
{
  users.users.gaurav = {
    isNormalUser = true;
    home = "/home/gaurav";
    hashedPasswordFile = config.age.secrets.user-passwd.path;
    uid = 1001;
    extraGroups = [
      "input"
      "networkmanager"
      "wheel"
    ]
    ++ (if config.programs.wireshark.enable then [ "wireshark" ] else [ ]);
  };
  users.groups.gaurav.gid = 1001;

  age.secrets = {
    user-passwd.rekeyFile = ../keys/secrets/gaurav-passwd.age;
  };
}

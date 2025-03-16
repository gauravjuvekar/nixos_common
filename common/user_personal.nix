{ ... }:
{
  users.users.gaurav =
    {
      isNormalUser = true;
      home = "/home/gaurav";
      uid = 1001;
      extraGroups =
        [
          "input"
          "networkmanager"
          "wheel"
        ];
    };
  users.groups.gaurav.gid = 1001;
}

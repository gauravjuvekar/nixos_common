{ ... }:
{
  networking.firewall =
    {
      enable = true;
      allowedTCPPortRanges = [ {from = 8000; to = 8999;} ];
      allowedUDPPortRanges = [ {from = 8000; to = 8999;} ];
    };
}

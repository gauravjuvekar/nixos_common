{ config, ... }:
{
  programs.wireshark = {
    enable = config.hostinfo.isLocalGraphical;
    dumpcap.enable = true;
    usbmon.enable = true;
  };
}

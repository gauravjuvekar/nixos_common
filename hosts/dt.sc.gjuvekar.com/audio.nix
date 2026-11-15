{
  lib,
  pkgs,
  ...
}:
let
  stockProfiles = builtins.readFile "${pkgs.pipewire}/share/alsa-card-profile/mixer/profile-sets/default.conf";
  profileFrom = [
    "[Mapping hdmi-stereo]"
    "[Mapping hdmi-stereo-extra1]"
    "(HDMI)"
    "(HDMI/DTS)"
    "(HDMI 2)"
    "(HDMI 2/DTS)"
    "(HDMI 3)"
    "(HDMI 3/DTS)"
    ".include 9999-custom.conf"
  ];
  profileTo = [
    "[Mapping right_monitor]"
    "[Mapping left_monitor]"
    "(DisplayPort 1)"
    "(DisplayPort 1/DTS)"
    "(DisplayPort 2)"
    "(DisplayPort 2/DTS)"
    "(DisplayPort 3)"
    "(DisplayPort 3/DTS)"
    ''
      [Profile multimonitor-stereo]
      description = Left and Right Monitors
      output-mappings = left_monitor right_monitor
    ''
  ];
  renameHdmiPort = port: label: {
    "alsa-card-profile/paths/hdmi-output-${toString port}.conf".text =
      builtins.replaceStrings
        [
          "description = HDMI / DisplayPort${if port == 0 then "" else " ${toString (port + 1)}"}"
        ]
        [ "description = ${label}" ]
        (
          builtins.readFile "${pkgs.pipewire}/share/alsa-card-profile/mixer/paths/hdmi-output-${toString port}.conf"
        );
  };
in
{
  environment.etc =
    renameHdmiPort 0 "Right"
    // renameHdmiPort 1 "Left"
    // renameHdmiPort 2 "Center"
    // {
      "alsa-card-profile/profile-sets/multimonitor-stereo.conf".text =
        assert lib.all (fragment: lib.hasInfix fragment stockProfiles) profileFrom;
        builtins.replaceStrings profileFrom profileTo stockProfiles;
    };

  services.pipewire.wireplumber.extraConfig."52-multimonitor-profile"."monitor.alsa.rules" = [
    {
      matches = [ { "device.name" = "alsa_card.pci-0000_01_00.1"; } ];
      actions."update-props" = {
        "device.profile-set" = "multimonitor-stereo.conf";
        "device.profile" = "multimonitor-stereo";
      };
    }
  ];
}

{ config, ... }:
{
  networking.networkmanager.ensureProfiles =
    {
      profiles =
        {
          gaurav1 = {
            connection = {
              id = "gaurav1";
              permission = "";
              type = "802-11-wireless";
              # interface-name
            };
            "802-11-wireless" = {
              mode = "infrastructure";
              ssid = "gaurav1";
            };
            "802-11-wireless-security" = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk-flags = "1"; # secrets from agent
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              method = "auto";
              addr-gen-mode = "default";
            };
          };
          nv_visitor = {
            connection = {
              id = "NV_VISITOR";
              permission = "";
              type = "802-11-wireless";
              # interface-name
            };
            "802-11-wireless" = {
              mode = "infrastructure";
              ssid = "NV_VISITOR";
            };
            "802-11-wireless-security" = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk-flags = "1"; # secrets from agent
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              method = "auto";
              addr-gen-mode = "default";
            };
          };
        };
      secrets.entries =
        let
          mkEntry = {profile, file}: {
            file = file;
            key = "psk";
            matchId = profile.connection.id;
            matchSetting = "802-11-wireless-security";
            matchType = profile.connection.type;
          };
        in
        [
          (mkEntry {
            profile = config.networking.networkmanager.ensureProfiles.profiles.gaurav1;
            file = config.age.secrets.wifi-passwd-gaurav1.path;})
          (mkEntry {
            profile = config.networking.networkmanager.ensureProfiles.profiles.nv_visitor;
            file = config.age.secrets.wifi-passwd-nv_visitor.path;})
        ];
    };


  age.secrets =
    {
      wifi-passwd-gaurav1.rekeyFile = ../keys/secrets/wifi-passwd-gaurav1.age;
      wifi-passwd-nv_visitor.rekeyFile = ../keys/secrets/wifi-passwd-nv_visitor.age;
    };
}

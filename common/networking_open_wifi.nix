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
              type = "wifi";
              # interface-name
            };
            wifi = {
              mode = "infrastructure";
              ssid = "gaurav1";
            };
            wifi-security = {
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
              type = "wifi";
              # interface-name
            };
            wifi = {
              mode = "infrastructure";
              ssid = "NV_VISITOR";
            };
            wifi-security = {
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
          gaurav1 = config.networking.networkmanager.ensureProfiles.profiles.gaurav1;
          nv_visitor = config.networking.networkmanager.ensureProfiles.profiles.nv_visitor;
        in
        [
          {
            file = config.age.secrets.wifi-passwd-gaurav1.path;
            key = "psk";
            matchId = gaurav1.connection.id;
            matchSetting = "wifi-security";
            matchType = gaurav1.connection.type;
          }
          {
            file = config.age.secrets.wifi-passwd-nv_visitor.path;
            key = "psk";
            matchId = nv_visitor.connection.id;
            matchSetting = "wifi-security";
            matchType = nv_visitor.connection.type;
          }
        ];
    };


  age.secrets =
    {
      wifi-passwd-gaurav1.rekeyFile = ../keys/secrets/wifi-passwd-gaurav1.age;
      wifi-passwd-nv_visitor.rekeyFile = ../keys/secrets/wifi-passwd-nv_visitor.age;
    };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  wifiInterface = "wlan0";
  lanInterface = "enabcm6e4ei0";
  ipv4Address = "172.16.50.1";
  ipv4Subnet = "172.16.50.0/24";
  ipv4DnsServers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  ipv6Address = "fd6a:6769:6f74:50::1";
  ipv6Subnet = "fd6a:6769:6f74:50::/64";
  ipv6LinkLocalSubnet = "fe80::/10";
  ipv6LinkLocalMulticastSubnet = "ff02::/16";
  ipv6GlobalUnicastSubnet = "2000::/3";
  ipv6DnsServers = [
    "2606:4700:4700::1111"
    "2620:fe::fe"
  ];
  nonInternetIpv4Ranges = {
    thisNetwork = "0.0.0.0/8";
    private10 = "10.0.0.0/8";
    shared = "100.64.0.0/10";
    loopback = "127.0.0.0/8";
    linkLocal = "169.254.0.0/16";
    private172 = "172.16.0.0/12";
    ietfProtocolAssignments = "192.0.0.0/24";
    documentationTestNet1 = "192.0.2.0/24";
    private192 = "192.168.0.0/16";
    benchmarking = "198.18.0.0/15";
    documentationTestNet2 = "198.51.100.0/24";
    documentationTestNet3 = "203.0.113.0/24";
    multicast = "224.0.0.0/4";
    reserved = "240.0.0.0/4";
  };
  nonInternetIpv6Ranges = {
    ietfProtocolAssignments = "2001::/23";
    documentationTestNet1 = "2001:db8::/32";
    sixToFour = "2002::/16";
    documentationTestNet2 = "3fff::/20";
  };
  homeAssistantHttpPort = config.services.home-assistant.config.http.server_port;
  matterApiPort = config.services.matterjs-server.port;
  httpsPort = 443;
  matterPort = 5540;
  mdnsPort = 5353;
  dhcpServerPort = 67;
  dhcpClientPort = 68;
  passwordFile = "/var/lib/gaurav-iot/wpa-passphrase";
  internetAllowedMacs = config.rpi.iot.internetAllowedMacs;
in
{
  options.rpi.iot.internetAllowedMacs = lib.mkOption {
    type = lib.types.listOf (lib.types.strMatching "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}");
    default = [ ];
    description = "Wi-Fi client MAC addresses permitted to reach the Internet and HTTPS on the Pi's public IPv6 addresses.";
  };

  config = {
    systemd.network.links."10-rpi-iot" = {
      matchConfig.MACAddress = "dc:a6:32:bb:35:09";
      linkConfig = {
        Name = wifiInterface;
        NamePolicy = "";
      };
    };

    systemd.network.networks."10-rpi-iot" = {
      matchConfig.Name = wifiInterface;
      address = [
        "${ipv4Address}/24"
        "${ipv6Address}/64"
      ];
      linkConfig.RequiredForOnline = false;
      networkConfig = {
        ConfigureWithoutCarrier = true;
        DHCP = "no";
        DHCPServer = true;
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv6";
        IPv6SendRA = true;
        # Avahi publishes rpi.local; resolved only performs mDNS lookups.
        MulticastDNS = "resolve";
        LLMNR = false;
      };
      # Android supports IPv6-only Wi-Fi, but its provisioning check excludes
      # ULA addresses. With only our fd6a:6769:6f74:50::/64, phones can report
      # "failed to obtain IP address". Supply IPv4 DHCP
      # alongside IPv6 SLAAC so phones can connect; retain IPv6 for Matter.
      # AOSP: packages/modules/Connectivity/framework/src/android/net/
      # LinkProperties.java (isIpv6Provisioned), LinkAddress.java (isGlobalPreferred).
      dhcpServerConfig = {
        ServerAddress = "${ipv4Address}/24";
        PoolOffset = 100;
        PoolSize = 100;
        EmitRouter = true;
        Router = ipv4Address;
        EmitDNS = true;
        DNS = ipv4DnsServers;
      };
      # All clients get a route; the firewall limits Internet access by MAC.
      ipv6SendRAConfig = {
        RouterLifetimeSec = if internetAllowedMacs != [ ] then 1800 else 0;
        OtherInformation = false;
        Managed = false;
        EmitDNS = true;
        DNS = ipv6DnsServers;
      };
      ipv6Prefixes = [ { Prefix = ipv6Subnet; } ];
    };

    # Keep learning the Ethernet IPv6 address and default route while routing.
    systemd.network.networks."10-rpi-lan".networkConfig.IPv6AcceptRA = true;

    services.hostapd = {
      enable = true;
      radios.${wifiInterface} = {
        countryCode = "US";
        band = "2g";
        channel = 6;
        wifi4.capabilities = [ "SHORT-GI-20" ];
        wifi5.enable = false;
        networks.${wifiInterface} = {
          ssid = "gaurav-iot";
          apIsolate = false;
          authentication = {
            mode = "wpa3-sae";
            saePasswords = [ { inherit passwordFile; } ];
          };
          settings = {
            ieee80211w = 2;
            sae_require_mfp = 1;
          };
        };
      };
    };

    systemd.services.gaurav-iot-password = {
      description = "Create the persistent IoT Wi-Fi password";
      before = [ "hostapd.service" ];
      requiredBy = [ "hostapd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "gaurav-iot";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        if [ ! -s ${passwordFile} ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 16 > ${passwordFile}.new
          mv ${passwordFile}.new ${passwordFile}
        fi
      '';
    };

    services.avahi.settings = {
      server.allow-interfaces = [
        lanInterface
        wifiInterface
      ];
      reflector.enable-reflector = false;
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    networking.firewall = {
      filterForward = true;
      interfaces.${wifiInterface} = {
        allowedTCPPorts = [
          httpsPort
          matterPort
        ];
        allowedUDPPorts = [
          dhcpServerPort
          mdnsPort
          matterPort
        ];
      };
      extraForwardRules = ''
        iifname "${wifiInterface}" oifname "${lanInterface}" accept
      '';
    };

    # Wi-Fi uses IPv4 DHCP plus IPv6 SLAAC/RDNSS on a stable ULA prefix.
    # Only allowlisted MACs may reach public destinations or Pi public IPv6 HTTPS.
    # Matter and mDNS stay on Wi-Fi; the HA and Matter APIs use loopback.
    # Apply these guards before the shared firewall's established/global accepts.
    networking.nftables.tables.rpi-iot = {
      family = "inet";
      content = ''
        set internet_macs {
          type ether_addr
          ${lib.optionalString (internetAllowedMacs != [ ]) ''
            elements = { ${lib.concatStringsSep ", " internetAllowedMacs} }
          ''}
        }

        set non_internet_ipv6 {
          type ipv6_addr
          flags interval
          elements = { ${lib.concatStringsSep ", " (lib.attrValues nonInternetIpv6Ranges)} }
        }

        set non_internet_ipv4 {
          type ipv4_addr
          flags interval
          elements = { ${lib.concatStringsSep ", " (lib.attrValues nonInternetIpv4Ranges)} }
        }

        chain input {
          type filter hook input priority filter - 10; policy accept;
          # Enforce service boundaries before shared established/global accepts.
          iifname != "lo" tcp dport { ${toString homeAssistantHttpPort}, ${toString matterApiPort} } drop
          iifname != { "lo", "${wifiInterface}" } tcp dport ${toString matterPort} drop
          iifname != { "lo", "${wifiInterface}" } udp dport ${toString matterPort} drop
          iifname != "${wifiInterface}" return
          # DHCP must work before a client has an address, regardless of allowlist.
          meta nfproto ipv4 udp sport ${toString dhcpClientPort} udp dport ${toString dhcpServerPort} accept
          meta nfproto ipv4 drop
          # The FIB follows DHCP/SLAAC changes automatically. Only HTTPS may
          # bypass the Wi-Fi destination guard, and only for allowlisted MACs.
          # An accept here still passes through the shared INPUT firewall.
          ether saddr @internet_macs ip6 daddr ${ipv6GlobalUnicastSubnet} ip6 daddr != @non_internet_ipv6 fib daddr type local tcp dport ${toString httpsPort} accept
          ip6 daddr != { ${ipv6Address}, ${ipv6LinkLocalSubnet}, ${ipv6LinkLocalMulticastSubnet} } drop
          ct state established,related accept
          tcp dport ${toString matterPort} accept
          udp dport { ${toString mdnsPort}, ${toString matterPort} } accept
          icmpv6 type {
            destination-unreachable, packet-too-big, time-exceeded, parameter-problem,
            nd-router-solicit, nd-neighbor-solicit, nd-neighbor-advert,
            mld-listener-query, mld-listener-report, mld-listener-done, mld2-listener-report
          } accept
          drop
        }

        chain forward {
          type filter hook forward priority filter - 10; policy accept;
          iifname "${wifiInterface}" jump from_iot
          oifname "${wifiInterface}" jump to_iot
        }

        chain from_iot {
          oifname != "${lanInterface}" drop
          ether saddr != @internet_macs drop
          meta nfproto ipv4 jump from_iot_ipv4
          meta nfproto ipv6 jump from_iot_ipv6
          drop
        }

        chain from_iot_ipv4 {
          ip saddr != ${ipv4Subnet} drop
          # Includes the Ethernet LAN (192.168.1.0/24), private and reserved ranges.
          # Add public IPv4 LAN prefixes here too if Ethernet ever uses them.
          ip daddr @non_internet_ipv4 drop
          accept
        }

        chain from_iot_ipv6 {
          ip6 saddr != ${ipv6Subnet} drop
          ip6 daddr != ${ipv6GlobalUnicastSubnet} drop
          ip6 daddr @non_internet_ipv6 drop
          # Ethernet hosts can have global IPv6 addresses, so the destination
          # range checks above cannot distinguish them from Internet hosts.
          # For an on-link destination, nftables reports the destination itself
          # as the next hop; Internet traffic goes through the upstream router.
          # Require a link-local next hop, as used by RA-learned routers.
          # This blocks direct access to globally addressed Ethernet hosts and
          # assumes the Ethernet default gateway uses a link-local address.
          # LAN prefixes routed via that gateway need separate exclusions.
          rt ip6 nexthop != ${ipv6LinkLocalSubnet} drop
          accept
        }

        chain to_iot {
          iifname "${lanInterface}" ip daddr ${ipv4Subnet} ct state established,related accept
          iifname "${lanInterface}" ip6 daddr ${ipv6Subnet} ct state established,related accept
          drop
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          iifname "${wifiInterface}" oifname "${lanInterface}" ip saddr ${ipv4Subnet} masquerade
          iifname "${wifiInterface}" oifname "${lanInterface}" ip6 saddr ${ipv6Subnet} masquerade
        }
      '';
    };
  };
}

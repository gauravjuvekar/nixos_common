{
  lib,
  options,
  pkgs,
  ...
}:
let
  defaultComponents = options.services.home-assistant.extraComponents.default;
in
{
  services.home-assistant = {
    enable = true;
    customComponents = [ pkgs.home-assistant-custom-components.auth_oidc ];
    extraComponents =
      defaultComponents ++ lib.optional (!(lib.elem "matter" defaultComponents)) "matter";
    config = {
      default_config = { };
      homeassistant.external_url = "https://sc.hass.gjuvekar.com";
      auth_oidc = {
        client_id = "homeassistant";
        discovery_url = "https://idm.gjuvekar.com/oauth2/openid/homeassistant/.well-known/openid-configuration";
        id_token_signing_alg = "ES256";
        roles = {
          admin = "homeassistant_admins@idm.gjuvekar.com";
          user = "homeassistant_users@idm.gjuvekar.com";
        };
      };
      http = {
        server_host = [
          "127.0.0.1"
          "::1"
        ];
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };
    };
  };

  services.matterjs-server = {
    enable = true;
    listenAddress = "127.0.0.1";
    openFirewall = false;
    extraArgs = [
      "--primary-interface=wlan0"
      # lt2 connects its Bluetooth adapter through an SSH tunnel to /ble.
      "--ble-proxy"
    ];
  };

  systemd.services.matterjs-server = {
    after = [ "hostapd.service" ];
    before = [ "home-assistant.service" ];
  };
}

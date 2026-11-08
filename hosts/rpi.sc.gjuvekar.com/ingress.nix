{
  config,
  lib,
  pkgs,
  ...
}:
let
  keyService = config.systemd.services."gcloud-service-account-keys@rpi-sc-ingress-acme";
  hosts = {
    "idm.gjuvekar.com" = "kanidm";
    "sc.idm.gjuvekar.com" = "kanidm";
    "sc.hass.gjuvekar.com" = "hello";
  };
  caddy = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/googleclouddns@v1.1.0" ];
    hash = "sha256-umFtfmCKlkDHOBcvd3TULodegnLkwg3wiD01q92qqLM=";
  };
in
{
  security.acme.defaults.email = "gauravjuvekar@gmail.com";

  services.caddy = {
    enable = true;
    package = caddy;
    # DNS-01 needs no inbound HTTP challenge listener. Serve HTTPS only.
    httpPort = null;
    openFirewall = true;
    acmeCA = "https://acme-v02.api.letsencrypt.org/directory";
    email = config.security.acme.defaults.email;
    logFormat = "level INFO";
    globalConfig = ''
      auto_https disable_redirects
      cert_issuer acme
    '';
    virtualHosts = lib.mapAttrs (
      host: application:
      let
        challengeDomain = "${lib.removeSuffix ".gjuvekar.com" host}.ingress-acme.rpi.sc.gjuvekar.com";
        site = pkgs.writeTextDir "index.html" ''
          <!doctype html>
          <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>Hello, world! — ${host}</title>
            </head>
            <body>
              <h1>Hello, world!</h1>
              <p>${host}</p>
            </body>
          </html>
        '';
      in
      {
        logFormat = "output stdout";
        extraConfig = ''
          tls {
            protocols tls1.3 tls1.3
            issuer acme {
              disable_http_challenge
              disable_tlsalpn_challenge
              dns googleclouddns {
                gcp_project gjuvekar-com-infra
                gcp_application_default /run/caddy/gcp-credentials.json
              }
              dns_challenge_override_domain ${challengeDomain}
              resolvers 1.1.1.1:53 [2606:4700:4700::1111]:53
            }
          }
        ''
        + (
          if application == "kanidm" then
            ''
              reverse_proxy https://${config.services.kanidm.server.settings.bindaddress} {
                header_up Host {http.request.host}
                transport http {
                  tls_server_name backend.sc.idm.gjuvekar.com
                }
              }
            ''
          else
            ''
              root * ${site}
              file_server
            ''
        );
      }
    ) hosts;
  };

  systemd.services.caddy = {
    requires = [ keyService.name ];
    after = [ keyService.name ];
    preStart = ''
      umask 077
      ${lib.getExe pkgs.jq} -n \
        --rawfile privateKey "$CREDENTIALS_DIRECTORY/private-key.pem" \
        --arg email ${lib.escapeShellArg keyService.environment.KEY_NAME} \
        '{type: "service_account", project_id: "gjuvekar-com-infra",
          client_email: $email, private_key: $privateKey,
          token_uri: "https://oauth2.googleapis.com/token"}' \
        > "$RUNTIME_DIRECTORY/gcp-credentials.json"
    '';
    serviceConfig = {
      LoadCredential = [ "private-key.pem:${keyService.environment.PRIVATE_KEY_PATH}" ];
      RuntimeDirectory = "caddy";
      RuntimeDirectoryMode = "0700";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
  };
}

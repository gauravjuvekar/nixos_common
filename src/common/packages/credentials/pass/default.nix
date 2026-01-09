{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
in
{
  config =
    let
      domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
    in
    {
      "home-manager" = lib.mkIf (domain_is_personal && hostinfo.isLocalInteractive) {
        home.packages = [
          pkgs.pass
        ];

        home.file.".password-store".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/auth/pass";
      };
      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

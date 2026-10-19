{
  config,
  inputs,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  usageinfo =
    {
      home-manager = osConfig.usageinfo;
      nixos-system = config.usageinfo;
    }
    ."${moduleContext}";

  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";

  domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
in
{
  config =
    {
      "home-manager" = lib.mkIf hostinfo.isLocalGraphical {
        home.packages = [
          pkgs.skills
          pkgs.t3code
        ]
        ++ lib.optionals domain_is_personal [
          pkgs.codex
          (inputs.jailed-agents.lib.${pkgs.stdenv.hostPlatform.system}.makeJailedCodex {
            pkg = pkgs.codex;
            enableNix = true;
            nixConfigDir = "/etc/nixos";
            enableGitWorktrees = {
              enable = true;
              mountGitConfig = true;
            };
            # Home Manager writes Git's global config here, rather than ~/.gitconfig.
            extraReadonlyDirs = [ "${config.xdg.configHome}/git" ];
            extraPkgs = lib.optionals config.programs.delta.enableGitIntegration [ pkgs.delta ];
          })
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

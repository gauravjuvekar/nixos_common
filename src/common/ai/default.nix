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
  jailedAgents = inputs.jailed-agents.lib.${pkgs.stdenv.hostPlatform.system};
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
          (jailedAgents.makeJailedCodex {
            pkg = pkgs.writeShellScriptBin "codex" ''
              exec ${lib.getExe pkgs.codex} -s danger-full-access "$@"
            '';
            enableNix = true;
            nixConfigDir = "/etc/nixos";
            baseJailOptions = [
              (jailedAgents.internals.jail.combinators.set-hostname hostinfo.fqdn)
            ] ++ jailedAgents.commonJailOptions;
            enableGitWorktrees = {
              enable = true;
              mountGitConfig = true;
            };
            # Home Manager writes Git's global config here, rather than ~/.gitconfig.
            extraReadonlyDirs = [ "${config.xdg.configHome}/git" ];
            extraReadwriteDirs = [ "${config.home.homeDirectory}/.agents/skills" ];
            extraPkgs = lib.optionals config.programs.delta.enableGitIntegration [ pkgs.delta ];
          })
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

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
  jailedCodexOptions = {
    pkg = pkgs.writeShellScriptBin "codex" ''
      exec ${lib.getExe pkgs.codex} -s danger-full-access "$@"
    '';
    enableNix = true;
    nixConfigDir = "/etc/nixos";
    baseJailOptions = [
      (jailedAgents.internals.jail.combinators.set-hostname hostinfo.fqdn)
    ]
    ++ jailedAgents.commonJailOptions;
    enableGitWorktrees = {
      enable = true;
      mountGitConfig = true;
    };
    # Home Manager writes Git's global config here, rather than ~/.gitconfig.
    extraReadonlyDirs = [ "${config.xdg.configHome}/git" ];
    extraReadwriteDirs = [ "${config.home.homeDirectory}/.agents/skills" ];
    extraPkgs = lib.optionals config.programs.delta.enableGitIntegration [ pkgs.delta ];
  };
  sharedProxy = import ./vey/service.nix {
    inherit pkgs allowedDomains;
  };
  allowedDomains = [
    "api.openai.com"
    "chatgpt.com"
    "auth.openai.com"
  ];
  restrictedNetworkOptions = {
    inherit pkgs jailedAgents;
    inherit (jailedCodexOptions) baseJailOptions;
  };
  restrictedNetworkTest = pkgs.callPackage ./tests/network.nix {
    inherit jailedAgents sharedProxy allowedDomains;
    networkOptions = restrictedNetworkOptions;
    hostname = hostinfo.fqdn;
    configDirs =
      jailedCodexOptions.extraReadonlyDirs
      ++ jailedCodexOptions.extraReadwriteDirs
      ++ [ jailedCodexOptions.nixConfigDir ];
  };
  jailedCodexRestricted =
    (jailedAgents.makeJailedCodex (
      jailedCodexOptions
      // {
        name = "jailed-codex-restricted";
        # Hosted web search and apps run beyond the jail's network restrictions.
        pkg = pkgs.writeShellScriptBin "codex" ''
          exec ${lib.getExe jailedCodexOptions.pkg} -c 'web_search="disabled"' -c 'features.apps=false' "$@"
        '';
        # The host daemon can fetch over the network even from an isolated jail.
        enableNix = false;
        baseJailOptions = import ./restricted-network.nix restrictedNetworkOptions;
      }
    )).overrideAttrs
      (old: {
        doCheck = true;
        checkPhase = old.checkPhase + ''
          ${lib.getExe restrictedNetworkTest} "$target"
        '';
      });
in
{
  config =
    {
      "home-manager" = lib.mkIf hostinfo.isLocalGraphical {
        systemd.user = lib.mkIf domain_is_personal {
          inherit (sharedProxy) sockets services;
        };
        home.packages = [
          pkgs.skills
          pkgs.t3code
        ]
        ++ lib.optionals domain_is_personal [
          pkgs.codex
          (jailedAgents.makeJailedCodex jailedCodexOptions)
          jailedCodexRestricted
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

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
  # jail.nix binds each store output; bubblewrap cannot mount onto a symlink
  # when the regular Codex jail already has /nix mounted.
  agentChromium = pkgs.chromium.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      mv "$sandbox" "$TMPDIR/chromium-sandbox-link"
      cp -rL "$TMPDIR/chromium-sandbox-link" "$sandbox"
    '';
  });
  agentBrowser = pkgs.symlinkJoin {
    name = "agent-browser-with-chromium";
    paths = [ pkgs.agent-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/agent-browser" \
        --set-default AGENT_BROWSER_EXECUTABLE_PATH ${lib.getExe agentChromium}
    '';
  };
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
        programs.codex = lib.mkIf domain_is_personal {
          enable = true;
          mutableSettings = true;
          settings.tui = {
            copy_on_select = "never";
            terminal_title = [ "project" ];
          };
        };
        programs.mr.settings.".agents/skills" = {
          checkout = "git clone git@github.com:gauravjuvekar/agent-skills.git skills";
        };
        systemd.user = lib.mkIf domain_is_personal {
          inherit (sharedProxy) sockets services;
        };
        home.packages = [
          pkgs.skills
          pkgs.t3code
        ]
        ++ lib.optionals domain_is_personal [
          agentBrowser
          (jailedAgents.makeJailedCodex (
            jailedCodexOptions
            // {
              extraPkgs = jailedCodexOptions.extraPkgs ++ [ agentBrowser ];
            }
          ))
          jailedCodexRestricted
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

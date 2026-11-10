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
  codexPackages = inputs.self.lib;
  codex = codexPackages.codex pkgs;
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
    inherit pkgs;
    codex = config.programs.codex-jail.package;
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
  restrictedCodex = codexPackages.makeRestrictedCodex jailedCodexOptions;
  inherit (restrictedCodex) sharedProxy allowedDomains;
  restrictedNetworkTest = pkgs.callPackage ./tests/network.nix {
    inherit jailedAgents sharedProxy allowedDomains;
    networkOptions = restrictedCodex.networkOptions;
    hostname = hostinfo.fqdn;
    configDirs =
      jailedCodexOptions.extraReadonlyDirs
      ++ jailedCodexOptions.extraReadwriteDirs
      ++ [ jailedCodexOptions.nixConfigDir ];
  };
  jailedCodexRestricted = restrictedCodex.overrideAttrs (old: {
    doCheck = true;
    checkPhase = old.checkPhase + ''
      ${lib.getExe restrictedNetworkTest} "$target"
    '';
  });
in
{
  imports = lib.optionals (moduleContext == "home-manager") [
    inputs.self.homeManagerModules.codex-jail
  ];

  config =
    {
      "home-manager" = lib.mkIf hostinfo.isLocalGraphical {
        programs.codex = lib.mkIf domain_is_personal {
          enable = true;
          package = codex;
          mutableSettings = true;
          settings.tui = {
            copy_on_select = "never";
            terminal_title = [ "project" ];
          };
        };
        programs.mr.settings.".agents/skills" = {
          checkout = "git clone git@github.com:gauravjuvekar/agent-skills.git skills";
        };
        programs.codex-jail = lib.mkIf domain_is_personal {
          enable = true;
          package = codex;
          jailedPackage = codexPackages.makeJailedCodex (
            jailedCodexOptions
            // {
              extraPkgs = jailedCodexOptions.extraPkgs ++ [ agentBrowser ];
            }
          );
          restrictedPackage = jailedCodexRestricted;
        };
        home.packages = [
          pkgs.skills
        ]
        ++ lib.optionals domain_is_personal [
          agentBrowser
          (pkgs.t3code.override { inherit codex; })
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

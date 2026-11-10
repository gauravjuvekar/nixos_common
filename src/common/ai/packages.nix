{ inputs }:
let
  defaultCodex =
    pkgs:
    let
      masterPkgs = import inputs.nixpkgs-master {
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (pkgs) config;
      };
    in
    masterPkgs.codex.overrideAttrs (old: {
      # The cargo hook requests system libraries absent from Codex's inputs.
      dontCargoUseSystemLibs = true;
      # LLVM optimization of Codex's large crates needs more compiler stack.
      env = old.env // {
        RUST_MIN_STACK = "67108864";
      };
    });
in
rec {
  codex = defaultCodex;

  makeJailedCodex =
    {
      pkgs,
      codex ? defaultCodex pkgs,
      name ? "codex-jailed",
      extraPkgs ? [ ],
      ...
    }@args:
    inputs.jailed-agents.lib.${pkgs.stdenv.hostPlatform.system}.makeJailedCodex (
      {
        pkg = pkgs.writeShellScriptBin "codex" ''
          exec ${pkgs.lib.getExe codex} -s danger-full-access "$@"
        '';
      }
      // builtins.removeAttrs args [
        "pkgs"
        "codex"
      ]
      // {
        inherit name extraPkgs;
      }
    );

  makeRestrictedCodex =
    {
      pkgs,
      codex ? defaultCodex pkgs,
      name ? "codex-restricted",
      allowedDomains ? [
        "api.openai.com"
        "chatgpt.com"
        "auth.openai.com"
      ],
      ...
    }@args:
    let
      jailedAgents = inputs.jailed-agents.lib.${pkgs.stdenv.hostPlatform.system};
      networkOptions = {
        inherit pkgs jailedAgents;
        baseJailOptions = args.baseJailOptions or jailedAgents.commonJailOptions;
      };
      sharedProxy = import ./vey/service.nix {
        inherit pkgs allowedDomains;
      };
      pkg = args.pkg or codex;
    in
    (makeJailedCodex (
      builtins.removeAttrs args [ "allowedDomains" ]
      // {
        inherit pkgs name;
        # Hosted web search and apps run beyond the jail's network restrictions.
        pkg = pkgs.writeShellScriptBin "codex" ''
          exec ${pkgs.lib.getExe pkg} -s danger-full-access -c 'web_search="disabled"' -c 'features.apps=false' "$@"
        '';
        # The host daemon can fetch over the network even from an isolated jail.
        enableNix = false;
        baseJailOptions = import ./restricted-network.nix networkOptions;
      }
    )).overrideAttrs
      (old: {
        passthru = (old.passthru or { }) // {
          inherit allowedDomains networkOptions sharedProxy;
        };
      });
}

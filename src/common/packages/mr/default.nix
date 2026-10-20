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

  domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
  pullPrimary = pkgs.writeShellScript "mr-update" ''
    set -e
    remote_head=$(git ls-remote --symref origin HEAD)
    primary_branch=$(printf '%s\n' "$remote_head" | sed -n 's|^ref: refs/heads/\(.*\)[[:space:]]HEAD$|\1|p')
    if [ -z "$primary_branch" ]; then
      echo "Could not determine origin's primary branch" >&2
      exit 1
    fi
    git pull "$@" origin "$primary_branch"
  '';
in
{
  config =
    {
      "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
        programs.mr.enable = true;
        programs.mr.settings = {
          DEFAULT.git_update = "${pullPrimary} \"$@\"";
          ".config/home-manager" = lib.mkIf domain_is_personal {
            checkout = "git clone git@github.com/gauravjuvekar/nixos_common.git";
          };
        };
        # mr applies defaults only to repository sections that follow them.
        home.file.".mrconfig".source = lib.mkForce (
          pkgs.writeText "mrconfig" (
            "[DEFAULT]\n"
            + lib.generators.toINIWithGlobalSection { } {
              globalSection = config.programs.mr.settings.DEFAULT;
              sections = builtins.removeAttrs config.programs.mr.settings [ "DEFAULT" ];
            }
          )
        );
      };

      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

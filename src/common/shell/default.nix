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
    lib.mkIf hostinfo.isLocalInteractive
      {
        "home-manager" = {
          programs.bash = {
            enable = true;
            initExtra = ''
              source "${pkgs.complete-alias}/bin/complete_alias"
              complete -F _complete_alias "''${!BASH_ALIASES[@]}"
            '';
          };

          programs.nushell = {
            enable = true;
            settings = {
              show_banner = false;
            };
            shellAliases = lib.mkForce { };
          };

          programs.zoxide = {
            enable = true;
            enableBashIntegration = true;
            options = [
              "--cmd"
              "j"
            ];
          };
          programs.dircolors.enable = true;
          programs.direnv = {
            enable = true;
            enableBashIntegration = true;
          };
          programs.fzf.enable = true;
          home.shellAliases = {
            "f" = "fzf";
            "LS" = "ls";
            "SL" = "ls";
            "sl" = "ls";
          };

          programs.atuin = {
            enable = true;
            enableBashIntegration = true;
            flags = [ "--disable-up-arrow" ];
            settings = {
              auto_sync = false;
              update_check = false;
              enter_accept = false;
            };
          };
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

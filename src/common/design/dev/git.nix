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
    {
      "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
        home.packages = [
          pkgs.bfg-repo-cleaner
          pkgs.gh
          pkgs.git
          pkgs.git-filter-repo
          pkgs.git-repo
          pkgs.glab
          (pkgs.writeShellApplication {
            name = "cm";
            runtimeInputs = [
              pkgs.git
            ];
            text = builtins.readFile ./myapps/cm;
          })
          (pkgs.writeShellApplication {
            name = "cam";
            runtimeInputs = [
              pkgs.git
            ];
            text = builtins.readFile ./myapps/cam;
          })
          (pkgs.writeShellApplication {
            name = "cum";
            runtimeInputs = [
              pkgs.git
            ];
            text = builtins.readFile ./myapps/cum;
          })
          (pkgs.writeShellApplication {
            name = "cuam";
            runtimeInputs = [
              pkgs.git
            ];
            text = builtins.readFile ./myapps/cuam;
          })
          (pkgs.writeShellApplication {
            name = "g-mirror-except";
            runtimeInputs = [
              pkgs.git
              pkgs.ripgrep
            ];
            text = builtins.readFile ./myapps/g-mirror-except;
          })
          (pkgs.writeShellApplication {
            name = "g-bp";
            runtimeInputs = [
              pkgs.git
              pkgs.ripgrep
            ];
            text = builtins.readFile ./myapps/g-bp;
          })
          (pkgs.writeShellApplication {
            name = "g-clean-untracked";
            runtimeInputs = [
              pkgs.git
              pkgs.parallel
              pkgs.ripgrep
            ];
            text = builtins.readFile ./myapps/g-clean-untracked;
          })
        ];

        home.shellAliases = {
          "a" = "git add";
          "b" = "git branch";
          "c" = "git commit";
          "ca" = "git commit --amend";
          "can" = "git commit --amend --reuse-message=HEAD";
          "ck" = "git checkout";
          "cu" = "git commit --all";
          "cua" = "git commit --all --amend";
          "cuan" = "git commit --all --amend --reuse-message=HEAD";
          "d" = "git diff";
          "da" = "git diff --cached";
          "dm" = "d $(gmb)";
          "fetch" = "git fetch";
          "g" = "git";
          "gmb" = "git merge-base master HEAD";
          "gvm" = "git mergetool --tool='nvim -d' --prompt";
          "log" = "git log";
          "logg" = "git log --oneline --graph --decorate=full";
          "pull" = "git pull";
          "push" = "git push";
          "rc" = "git rebase --continue";
          "s" = "git status";
        };

        programs.git = {
          enable = true;
          settings = {
            push = {
              default = "simple";
              autoSetupRemote = true;
            };
            safe = {
              directory = [
                "/etc/nixos"
              ];
            };
            url = {
              "git@github.com:" = {
                insteadOf = "https://github.com/";
              };
            };
            user = {
              name = hostinfo.primaryFullname;
            };
          };
        };
      };

      "nixos-system" = {
        environment.systemPackages = [
          pkgs.git
        ];
      };
    }
    ."${moduleContext}";
}

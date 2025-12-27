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
        home.packages = lib.lists.flatten [
          (lib.lists.optional hostinfo.isLocalGraphical pkgs.neovide)
          (lib.hiPrio pkgs.gcc) # Still need a compiler for treesitter # HOLY SHIT, Clang is broken GH 277564, 153759, 147342
          pkgs.ltex-ls
          pkgs.lua-language-server
          pkgs.nixd
          pkgs.nodePackages.bash-language-server
          pkgs.nodePackages.nodejs
          pkgs.nodePackages.vim-language-server
          pkgs.nodePackages.vscode-json-languageserver
          pkgs.perlnavigator
          pkgs.pyright
          pkgs.stylua
          pkgs.tree-sitter
          pkgs.vale
          pkgs.yaml-language-server
        ];

        programs.neovim = {
          enable = true;
          defaultEditor = true;
          extraConfig = ''
            set runtimepath^=~/.vim runtimepath+=~/.vim/after
            let &packpath = &runtimepath
            source ~/.vim/vimrc
          '';
          viAlias = true;
          vimAlias = true;
          vimdiffAlias = true;
        };

        home.shellAliases = {
          "e" = "nvim";
          "v" = "nvim -R";
        };
      };

      "nixos-system" = {
        # Enable it system-wide too
        programs.neovim = {
          # nano is horror
          defaultEditor = true;
          enable = true;
        };
      };
    }
    ."${moduleContext}";
}

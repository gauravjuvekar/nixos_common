{ pkgs, ... }:
{
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
  home.packages = with pkgs; [
    (lib.hiPrio gcc) # Still need a compiler for treesitter # HOLY SHIT, Clang is broken GH 277564, 153759, 147342
    ltex-ls
    lua-language-server
    nixd
    nodePackages.bash-language-server
    nodePackages.nodejs
    nodePackages.vim-language-server
    nodePackages.vscode-json-languageserver
    perlnavigator
    pyright
    stylua
    tree-sitter
    vale
    yaml-language-server
  ];
}

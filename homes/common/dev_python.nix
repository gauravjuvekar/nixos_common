{ pkgs, ... }:
{
  home.packages = with pkgs; [
    isort
    poetry
    python3
    uv
    yapf
  ];
}

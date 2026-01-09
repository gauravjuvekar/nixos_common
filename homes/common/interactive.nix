{ pkgs, ... }:
{
  home.packages = with pkgs; [
    age
    bat
    file
    inetutils
    inotify-tools
    jq
    jqp
    libsecret
    moreutils
    openssl
    rage
    rsync
    step-cli
    watchexec
    watchlog
    watchman
    yq
  ];
}

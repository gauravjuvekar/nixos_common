{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      mate.atril
      pdfarranger
      sioyek
    ];
}

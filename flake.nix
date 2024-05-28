{
  description = "Common flakes for all my systems";

  inputs =
    {
      nixpkgs =
        {
          url = "github:gauravjuvekar/nixpkgs/fqdn";
        };
    };

  outputs = { self, nixpkgs }:
    {
      nixosConfigurations =
        {
          gaurav-nixlt = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules =
                [
                  ./hosts/gaurav-nixlt.roam.gjuvekar.com/configuration.nix
                ];
            };
          "dt.sc.gjuvekar.com" = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules =
                [
                  ./hosts/dt.sc.gjuvekar.com/configuration.nix
                ];
            };
          live = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules =
                [
                  (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix")
                  ./hosts/live/configuration.nix
                ];
            };
        };
    };
}

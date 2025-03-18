{
  description = "Common flakes for all my systems";

  inputs =
    {
      flake-utils =
        {
          url = "github:numtide/flake-utils";
        };
      nixpkgs =
        {
          url = "github:NixOS/nixpkgs/nixos-unstable";
        };
      disko =
        {
          url = "github:nix-community/disko";
          inputs.nixpkgs.follows = "nixpkgs";
        };
    };

  outputs = { nixpkgs, flake-utils, ... }@inputs:
    {
      nixosConfigurations =
        {
          gaurav-nixlt = nixpkgs.lib.nixosSystem {
              system = flake-utils.lib.system.x86_64-linux;
              modules =
                [
                  ./hosts/gaurav-nixlt.roam.gjuvekar.com/configuration.nix
                ];
            };
          "dt.sc.gjuvekar.com" = nixpkgs.lib.nixosSystem {
              system = flake-utils.lib.system.x86_64-linux;
              modules =
                [
                  ./hosts/dt.sc.gjuvekar.com/configuration.nix
                ];
            };
          "lt2.roam.gjuvekar.com" = nixpkgs.lib.nixosSystem {
              system = flake-utils.lib.system.x86_64-linux;
              modules =
                [
                  inputs.disko.nixosModules.default
                  ./hosts/lt2.roam.gjuvekar.com/configuration.nix
                ];
            };
          live = nixpkgs.lib.nixosSystem {
              system = flake-utils.lib.system.x86_64-linux;
              modules =
                [
                  (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix")
                  ./hosts/live/configuration.nix
                ];
            };
        };
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.nixos-anywhere =
          import ./nixos-anywhere/shell.nix { inherit pkgs; };
      }
    );
}

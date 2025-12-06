{
  description = "Common flakes for all my systems";

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    droid-sans-mono-dotted = {
      url = "github:gauravjuvekar/droid-sans-mono-dotted";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fsaction = {
      url = "github:gauravjuvekar/fsaction";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    systems = {
      url = "github:nix-systems/default";
    };
  };

  outputs =
    { self, ... }@inputs:
    {
      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations;
      };
      nixosConfigurations = {
        gaurav-nixlt = inputs.nixpkgs.lib.nixosSystem {
          system = inputs.flake-utils.lib.system.x86_64-linux;
          modules = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            ./hosts/gaurav-nixlt.roam.gjuvekar.com/configuration.nix
          ];
        };
        "dt.sc.gjuvekar.com" = inputs.nixpkgs.lib.nixosSystem {
          system = inputs.flake-utils.lib.system.x86_64-linux;
          modules = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            ./src/modules/hostinfo/default.nix
            ./hosts/dt.sc.gjuvekar.com/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = {
                inputs = inputs;
                firefox-addons = inputs.firefox-addons.outputs.packages.x86_64-linux;
                droid-sans-mono-dotted = inputs.droid-sans-mono-dotted.outputs.packages.x86_64-linux;
              };
              home-manager.users."gaurav" = {
                imports = [
                  ./homes/hosts/gaurav-dt/home.nix
                ];
              };
            }
          ];
        };
        "lt2.roam.gjuvekar.com" = inputs.nixpkgs.lib.nixosSystem {
          system = inputs.flake-utils.lib.system.x86_64-linux;
          modules = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            inputs.disko.nixosModules.default
            ./src/modules/hostinfo/default.nix
            ./hosts/lt2.roam.gjuvekar.com/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = {
                inputs = inputs;
                firefox-addons = inputs.firefox-addons.outputs.packages.x86_64-linux;
                droid-sans-mono-dotted = inputs.droid-sans-mono-dotted.outputs.packages.x86_64-linux;
              };
              home-manager.users."gaurav" = {
                imports = [
                  ./homes/hosts/lt2.roam.gjuvekar.com/gaurav/home.nix
                ];
              };
            }
          ];
        };
        "gjuvekar-lt.client.nvidia.com" = inputs.nixpkgs.lib.nixosSystem {
          system = inputs.flake-utils.lib.system.x86_64-linux;
          modules = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            ./hosts/gjuvekar-lt.client.nvidia.com/configuration.nix
          ];
        };
        live = inputs.nixpkgs.lib.nixosSystem {
          system = inputs.flake-utils.lib.system.x86_64-linux;
          modules = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix")
            ./hosts/live/configuration.nix
          ];
        };
      };
    }
    // inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.agenix-rekey.overlays.default
          ];
        };
      in
      {
        devShells.deploy = import ./deploy/shell.nix { inherit pkgs; };
        formatter = pkgs.writeShellApplication {
          name = "treefmt-repo";
          runtimeInputs = [
            pkgs.alejandra
            pkgs.nixfmt
            pkgs.treefmt
          ];
          text = "treefmt";
        };
      }
    )
    // (
      let
        system = "x86_64-linux";
        pkgs = import inputs.nixpkgs {
          system = system;
          config = {
            allowUnfreePredicate = (
              pkgname:
              builtins.elem (inputs.nixpkgs.lib.getName pkgname) [
              ]
            );
          };
        };
        extraSpecialArgs = {
          inputs = inputs;
          firefox-addons = inputs.firefox-addons.outputs.packages.${system};
          droid-sans-mono-dotted = inputs.droid-sans-mono-dotted.outputs.packages.${system};
        };
      in
      {
        homeConfigurations."gaurav@dt.sc.gjuvekar.com" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          inherit extraSpecialArgs;
          modules = [
            ./homes/hosts/gaurav-dt/home.nix
          ];
        };
        homeConfigurations."gaurav@gaurav-nixlt" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          inherit extraSpecialArgs;
          modules = [
            ./homes/hosts/gaurav-nixlt/home.nix
          ];
        };
      }
    );
}

{
  description = "Common home-manager configuration for multiple hosts";

  inputs =
    {
      flake-utils.url = "github:numtide/flake-utils";

      droid-sans-mono-dotted =
        {
          url = "github:gauravjuvekar/droid-sans-mono-dotted";
          inputs.nixpkgs.follows = "nixpkgs";
          inputs.flake-utils.follows = "flake-utils";
        };

      firefox-addons =
        {
          url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
          inputs.nixpkgs.follows = "nixpkgs";
        };

      home-manager =
        {
          url = "github:nix-community/home-manager";
          inputs.nixpkgs.follows = "nixpkgs";
        };

      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

      fsaction =
        {
          url = "github:gauravjuvekar/fsaction";
          inputs.nixpkgs.follows = "nixpkgs";
          inputs.flake-utils.follows = "flake-utils";
        };
    };

  outputs = { ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs =
        import inputs.nixpkgs {
          system = system;
          config =
            {
              allowUnfreePredicate =
                (
                  pkgname: builtins.elem (inputs.nixpkgs.lib.getName pkgname)
                    [
                    ]
                );
            };
        };
      extraSpecialArgs =
        {
          inputs = inputs;
          firefox-addons = inputs.firefox-addons.outputs.packages.${system};
          droid-sans-mono-dotted = inputs.droid-sans-mono-dotted.outputs.packages.${system};
        };
    in
    {
      homeConfigurations."gaurav@dt.sc.gjuvekar.com" =
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          inherit extraSpecialArgs;
          modules =
            [
              ./hosts/gaurav-dt/home.nix
            ];
        };
      homeConfigurations."gaurav@gaurav-nixlt" =
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          inherit extraSpecialArgs;
          modules =
            [
              ./hosts/gaurav-nixlt/home.nix
            ];
        };
    };
}

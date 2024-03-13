{
  description = "flake for gaurav-nixlt";

  inputs =
    {
      nixpkgs =
        {
          url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";
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
                  ./configuration.nix
                ];
            };
        };
    };
}

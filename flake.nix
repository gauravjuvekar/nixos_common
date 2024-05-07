{
  description = "Common flakes for all my systems";

  inputs =
    {
      nixpkgs =
        {
          url = "github:NixOS/nixpkgs/nixos-unstable";
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
                  ./hosts/gaurav-nixlt/configuration.nix
                ];
            };
        };
    };
}

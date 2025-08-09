{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, darwin, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; };
      in {
        darwinConfigurations."my-mac" = darwin.lib.darwinSystem {
          modules = [
            ./darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.users."shanepadgett" = import ./home.nix;
            }
          ];
          specialArgs = { inherit pkgs; };
        };
      }
    );
}

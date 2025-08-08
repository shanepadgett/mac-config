{
  description = "macOS declarative config";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    darwin.url       = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }:
  let
    system = "aarch64-darwin";
    pkgs   = import nixpkgs { inherit system; };
  in {
    darwinConfigurations = {
      my-mac = darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./darwin-configuration.nix
          home-manager.nixosModules.home-manager
        ];
        specialArgs = { inherit pkgs; };
      };
    };
    packages.install = darwinConfigurations.my-mac.config.system.build.darwin-rebuild;
  };
}

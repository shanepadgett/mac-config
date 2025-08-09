{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: {
    darwinConfigurations = {
      shanepadgett = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shanepadgett = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };
}







# OLD CONFIG
# {
#   description = "macOS declarative config";

#   inputs = {
#     nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
#     darwin.url       = "github:LnL7/nix-darwin";
#     home-manager.url = "github:nix-community/home-manager";
#   };

#   outputs = { self, nixpkgs, darwin, home-manager, ... }:
#   let
#     system = "aarch64-darwin";
#     pkgs   = import nixpkgs { inherit system; };
#   in {
#     darwinConfigurations = {
#       my-mac = darwin.lib.darwinSystem {
#         inherit system;
#         modules = [
#           ./darwin-configuration.nix
#           home-manager.nixosModules.home-manager
#         ];
#         specialArgs = { inherit pkgs; };
#       };
#     };
#     packages.install = self.darwinConfigurations.my-mac.config.system.build.darwin-rebuild;
#   };
# }

{ pkgs, templatesDir }:
let
  callPackage = pkgs.callPackage;
in
{
  gcp = callPackage ./gcp.nix { };

  "delete-repo" = callPackage ./delete-repo.nix { };

  "docker-cleanup" = callPackage ./docker-cleanup.nix { };

  "git-init" = callPackage ./git-init.nix {
    inherit templatesDir;
  };

  "git-credentials" = callPackage ./git-credentials.nix { };
}
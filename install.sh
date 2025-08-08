#!/usr/bin/env bash
set -euo pipefail

FLAKE="github:shanepadgett/mac-config#my-mac"

# 1) Install Nix if missing
if ! command -v nix &>/dev/null; then
  echo "→ Installing Nix…"
  curl -L https://nixos.org/nix/install | sh
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# 2) Enable flakes
mkdir -p ~/.config/nix
grep -qxF "experimental-features = nix-command flakes" \
  ~/.config/nix/nix.conf || \
  echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf

# 3) Build activation package
echo "→ Building config..."
nix build "$FLAKE.darwinConfigurations.my-mac.activationPackage" \
  --impure --print-build-logs

# 4) Apply config
./result/sw/bin/darwin-rebuild switch --flake "$FLAKE"

echo "✅ Home configuration applied!"

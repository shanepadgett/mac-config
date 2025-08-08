#!/usr/bin/env bash
set -euo pipefail

FLAKE="github:shanepadgett/mac-config#my-mac"

# 1) Install Nix if missing
if ! command -v nix &>/dev/null; then
  echo "→ Installing Nix…"
  curl -L https://nixos.org/nix/install | sh
  
  # Try to source nix.sh if it exists
  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
  
  # Verify Nix is now available
  if ! command -v nix &>/dev/null; then
    echo "→ Nix installed but requires shell restart."
    echo "→ Please restart your terminal or run 'source ~/.nix-profile/etc/profile.d/nix.sh'"
    echo "→ Then run this script again"
    exit 1
  fi
  
  echo "→ Nix installed and initialized successfully"
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
if [ ! -f ./result/sw/bin/darwin-rebuild ]; then
  echo "→ Error: darwin-rebuild not found. Building might have failed."
  exit 1
fi

./result/sw/bin/darwin-rebuild switch --flake "$FLAKE"

echo "✅ Home configuration applied!"

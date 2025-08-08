#!/usr/bin/env zsh
set -euo pipefail

# FLAKE="."
CONFIG_DIR="~/.config/mac-config"
git clone https://github.com/shanepadgett/mac-config.git $CONFIG_DIR
cd $CONFIG_DIR

if ! command -v nix &>/dev/null; then
  echo "→ Installing Nix…"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm --force

  if ! command -v nix &>/dev/null; then
    echo "→ Sourcing Nix"
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  if ! command -v nix &>/dev/null; then
    echo "→ Nix installed but requires shell restart."
    echo "→ Please restart your terminal or run 'source ~/.nix-profile/etc/profile.d/nix.sh'"
    echo "→ Then run this script again"
    exit 1
  fi

  echo "→ Nix installed and initialized successfully"
fi

nix run github:LnL7/nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#shanepadgett


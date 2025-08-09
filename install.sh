#!/usr/bin/env zsh
set -euo pipefail

if [[ $OSTYPE != "darwin"* ]]; then
  echo "This script is designed for macOS only."
  exit 1
fi

INSTALL_DIR="$HOME/.config/mac-config"
REPO_URL="https://github.com/shanepadgett/mac-config.git"

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

# Install Git via Nix and clone repository
echo "→ Installing Git via Nix…"
nix-env -iA nixpkgs.git

echo "→ Cloning configuration repository…"
if [ ! -d "$INSTALL_DIR" ]; then
  git clone "$REPO_URL" "$INSTALL_DIR"
  echo "→ Repository cloned to $INSTALL_DIR"
else
  echo "→ Repository already exists at $INSTALL_DIR"
fi

cd "$INSTALL_DIR"

nix run github:LnL7/nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#shanepadgett

echo "→ Installation complete!"
echo ""
echo "Your configuration repository is now set up at $INSTALL_DIR"
echo "You can edit your dotfiles directly (e.g., ~/.zshrc, ~/.aliases) and changes will persist."
echo "To commit changes back to GitHub:"
echo "  cd $INSTALL_DIR"
echo "  git add ."
echo "  git commit -m 'Update configuration'"
echo "  git push"


#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }

if ! have stow; then
  echo "[error] stow is not installed. Run ./scripts/install_favorites.sh first."
  exit 1
fi

cd "$DOTFILES_DIR"

packages=()
[[ -d "$DOTFILES_DIR/nvim" ]] && packages+=("nvim")
[[ -d "$DOTFILES_DIR/zsh" ]] && packages+=("zsh")

echo "[stow] Installing packages: ${packages[*]}"

# --adopt is intentionally NOT used: we do not want to silently absorb random files.
stow --target="$HOME" --restow "${packages[@]}"

echo "[ok] Dotfiles installed."
echo "     Start a fresh shell with: exec zsh"

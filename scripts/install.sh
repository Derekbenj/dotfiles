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

# If bootstrap created a placeholder ~/.zshrc only to suppress zsh-newuser-install,
# remove it so Stow can create the real symlink. Do not remove a real user config.
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
  if grep -qE 'temporary bootstrap zshrc|Temporary \.zshrc created by bootstrap' "$HOME/.zshrc" 2>/dev/null; then
    echo "[stow] Removing temporary bootstrap ~/.zshrc so zsh can be stowed."
    rm -f "$HOME/.zshrc"
  else
    echo "[error] $HOME/.zshrc exists and is not a symlink."
    echo "        Stow will not overwrite it."
    echo "        Back it up, then rerun:"
    echo "          mv ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
    echo "          cd ~/dotfiles && ./scripts/install.sh"
    exit 1
  fi
fi

packages=()
[[ -d "$DOTFILES_DIR/nvim" ]] && packages+=("nvim")
[[ -d "$DOTFILES_DIR/zsh" ]] && packages+=("zsh")

echo "[stow] Installing packages: ${packages[*]}"
stow --target="$HOME" --restow "${packages[@]}"

echo "[ok] Dotfiles installed."
echo "     Start a fresh shell with: exec zsh"

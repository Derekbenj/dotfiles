#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_HOME="${HOME}"
PACKAGES=(nvim zsh)

if ! command -v stow >/dev/null 2>&1; then
  echo "[error] GNU Stow is not installed. Run ./scripts/install_favorites.sh first, or install stow manually."
  exit 1
fi

mkdir -p "$TARGET_HOME/.config"

# Back up real files/dirs that would conflict with Stow. Existing symlinks are left alone.
backup_path() {
  local path="$1"
  if [[ -e "$path" && ! -L "$path" ]]; then
    local backup="${path}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "[backup] $path -> $backup"
    mv "$path" "$backup"
  fi
}

backup_path "$TARGET_HOME/.zshrc"
backup_path "$TARGET_HOME/.config/nvim"

cd "$DOTFILES_DIR"
echo "[stow] Installing packages: ${PACKAGES[*]}"
stow --target="$TARGET_HOME" --restow "${PACKAGES[@]}"

echo "[ok] Dotfiles installed. Open a new shell or run: source ~/.zshrc"

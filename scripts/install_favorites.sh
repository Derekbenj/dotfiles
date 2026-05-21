#!/usr/bin/env bash
set -euo pipefail

# Installs Derek's preferred baseline dev tools on Ubuntu/Debian/Distrobox.
# Includes: zsh, git, curl, stow, direnv, zoxide, Node.js/npm, Rust/rustup, uv via Cargo, Oh My Zsh.

if [[ "${EUID}" -eq 0 ]]; then
  echo "[error] Do not run this script as root. It will use sudo when needed."
  exit 1
fi

have() { command -v "$1" >/dev/null 2>&1; }

if have apt-get; then
  echo "[apt] Installing baseline packages..."
  sudo apt-get update
  sudo apt-get install -y \
    zsh git curl ca-certificates build-essential pkg-config libssl-dev \
    stow direnv zoxide unzip nodejs npm
else
  echo "[warn] apt-get not found. Install zsh git curl stow direnv zoxide nodejs npm manually for this OS."
fi


if have node; then
  echo "[node] Node.js: $(node --version)"
else
  echo "[warn] node was not found after package install."
fi

if have npm; then
  echo "[npm] npm: $(npm --version)"
else
  echo "[warn] npm was not found after package install."
fi

if ! have rustup && ! have cargo; then
  echo "[rust] Installing Rust with rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
  echo "[rust] Rust/Cargo already installed."
fi

# Load Cargo into this script session.
if [[ -r "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

if have cargo; then
  if ! have uv; then
    echo "[uv] Installing uv via Cargo..."
    cargo install uv
  else
    echo "[uv] uv already installed."
  fi
else
  echo "[warn] cargo still not found, so uv was not installed. Open a new shell and run: cargo install uv"
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "[omz] Installing Oh My Zsh without changing shell immediately..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[omz] Oh My Zsh already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ -d "$HOME/.oh-my-zsh" && ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  echo "[omz] Installing zsh-autosuggestions plugin..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if have zsh; then
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    echo "[zsh] Attempting to set default shell to $zsh_path"
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    if chsh -s "$zsh_path"; then
      echo "[zsh] Default shell changed. Log out/in for it to fully apply."
    else
      echo "[warn] chsh failed. In some Distrobox/container setups this is normal. You can still run: zsh"
    fi
  else
    echo "[zsh] zsh is already your default shell."
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/install.sh" ]]; then
  echo "[dotfiles] Running Stow install..."
  "$SCRIPT_DIR/install.sh"
fi

cat <<'MSG'

[done] Favorites installed.

Container prompt tag:
  Enable for this machine/container:
    echo 'export DOTFILES_CONTAINER_PROMPT=1' >> ~/.zshrc.local
    source ~/.zshrc

  Disable:
    sed -i '/DOTFILES_CONTAINER_PROMPT/d' ~/.zshrc.local

Commit dotfile changes:
  cd ~/dotfiles
  git status
  git add zsh/.zshrc nvim/.config/nvim scripts README.md
  git commit -m "Update dotfiles"
  git push
MSG

#!/usr/bin/env bash
set -euo pipefail

# Installs Derek's preferred baseline dev tools on Ubuntu/Debian/Distrobox.
# Includes: zsh, git, curl, stow, direnv, zoxide, Node.js/npm,
# latest Neovim release tarball, latest lazygit release tarball,
# Rust/rustup, uv via Cargo, Oh My Zsh, zsh-autosuggestions,
# and useful LazyVim tools.

if [[ "${EUID}" -eq 0 ]]; then
  echo "[error] Do not run this script as root. It will use sudo when needed."
  exit 1
fi

have() {
  command -v "$1" >/dev/null 2>&1
}

install_latest_neovim() {
  local arch asset url tmpdir installed_version

  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)
      asset="nvim-linux-x86_64.tar.gz"
      ;;
    aarch64|arm64)
      asset="nvim-linux-arm64.tar.gz"
      ;;
    *)
      echo "[nvim] Unsupported architecture for official binary: $arch"
      echo "[nvim] Falling back to apt-provided neovim if available."
      return 0
      ;;
  esac

  url="https://github.com/neovim/neovim/releases/latest/download/${asset}"
  tmpdir="$(mktemp -d)"

  echo "[nvim] Installing latest Neovim release from: $url"
  curl -fL "$url" -o "$tmpdir/$asset"
  tar -xzf "$tmpdir/$asset" -C "$tmpdir"

  sudo rm -rf /opt/nvim-linux-x86_64 /opt/nvim-linux-arm64 /opt/nvim
  sudo mv "$tmpdir"/nvim-linux-* /opt/nvim
  sudo ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim

  rm -rf "$tmpdir"

  if have nvim; then
    installed_version="$(/usr/local/bin/nvim --version | head -n1 || true)"
    echo "[nvim] Installed: $installed_version"
    echo "[nvim] Path: $(command -v nvim)"
  else
    echo "[warn] nvim was installed to /usr/local/bin/nvim but is not on PATH."
  fi
}

install_latest_lazygit() {
  local arch asset_arch latest_url version asset url tmpdir installed_version

  if have lazygit; then
    installed_version="$(lazygit --version 2>/dev/null || true)"
    echo "[lazygit] Already installed: $installed_version"
    return 0
  fi

  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)
      asset_arch="x86_64"
      ;;
    aarch64|arm64)
      asset_arch="arm64"
      ;;
    *)
      echo "[lazygit] Unsupported architecture for official binary: $arch"
      return 0
      ;;
  esac

  echo "[lazygit] Resolving latest lazygit release..."
  latest_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/jesseduffield/lazygit/releases/latest)"
  version="${latest_url##*/}"
  version="${version#v}"

  if [[ -z "$version" || "$version" == "latest" ]]; then
    echo "[warn] Could not resolve latest lazygit version from: $latest_url"
    return 0
  fi

  asset="lazygit_${version}_Linux_${asset_arch}.tar.gz"
  url="https://github.com/jesseduffield/lazygit/releases/latest/download/${asset}"
  tmpdir="$(mktemp -d)"

  echo "[lazygit] Installing latest lazygit from: $url"
  curl -fL "$url" -o "$tmpdir/$asset"
  tar -xzf "$tmpdir/$asset" -C "$tmpdir" lazygit
  sudo install -m 0755 "$tmpdir/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmpdir"

  if have lazygit; then
    echo "[lazygit] Installed: $(lazygit --version 2>/dev/null || true)"
    echo "[lazygit] Path: $(command -v lazygit)"
  else
    echo "[warn] lazygit was installed to /usr/local/bin/lazygit but is not on PATH."
  fi
}

if have apt-get; then
  echo "[apt] Installing baseline packages..."
  sudo apt-get update
  sudo apt-get install -y \
    zsh \
    git \
    curl \
    ca-certificates \
    build-essential \
    pkg-config \
    libssl-dev \
    stow \
    direnv \
    zoxide \
    unzip \
    xz-utils \
    ripgrep \
    fd-find \
    nodejs \
    npm
else
  echo "[warn] apt-get not found. Install baseline tools manually for this OS."
fi

# Ubuntu/Debian package is called fd-find and installs the binary as fdfind.
# Many Neovim plugins expect the command name to be fd.
if have fdfind && ! have fd; then
  echo "[fd] Creating /usr/local/bin/fd -> $(command -v fdfind)"
  sudo ln -sfn "$(command -v fdfind)" /usr/local/bin/fd
fi

install_latest_neovim
install_latest_lazygit

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
    echo "[uv] uv already installed: $(uv --version 2>/dev/null || true)"
  fi
else
  echo "[warn] cargo still not found, so uv was not installed. Open a new shell and run: cargo install uv"
fi

# Some shells export ZSH=/some/old/path. If we leave that in the environment,
# the official installer may use the wrong directory and fail. Keep OMZ tied
# to this HOME unless explicitly overridden.
OMZ_DIR="${DOTFILES_OMZ_DIR:-$HOME/.oh-my-zsh}"

if [[ -d "$OMZ_DIR" ]]; then
  echo "[omz] Oh My Zsh already installed at $OMZ_DIR."
else
  echo "[omz] Installing Oh My Zsh to $OMZ_DIR without changing shell immediately..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$OMZ_DIR" \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

if [[ -d "$OMZ_DIR" && ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  echo "[omz] Installing zsh-autosuggestions plugin..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo "[omz] zsh-autosuggestions already installed or Oh My Zsh missing."
fi

if have zsh; then
  zsh_path="$(command -v zsh)"
  current_login_shell="$(getent passwd "$USER" | cut -d: -f7 || true)"

  if [[ "$current_login_shell" != "$zsh_path" ]]; then
    echo "[zsh] Attempting to set default shell to $zsh_path"

    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    if chsh -s "$zsh_path"; then
      echo "[zsh] Default shell changed. Log out/in for it to fully apply."
    else
      echo "[warn] chsh failed. In some Distrobox/container setups this is normal."
      echo "[warn] The generic enter script will still launch zsh directly when available."
    fi
  else
    echo "[zsh] zsh is already your login shell."
  fi
else
  echo "[warn] zsh was not found."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -x "$SCRIPT_DIR/install.sh" ]]; then
  echo "[dotfiles] Running Stow install..."
  "$SCRIPT_DIR/install.sh"
else
  echo "[warn] $SCRIPT_DIR/install.sh not found or not executable; skipping Stow install."
fi

cat <<'MSG'

[done] Favorites installed.

Start using zsh now:
  exec zsh

Container prompt tag:
  Enable for this machine/container:
    cat > ~/.zshrc.local <<'EOF_LOCAL'
export DOTFILES_CONTAINER_PROMPT=1
export DOTFILES_CONTAINER_NAME="generic"
EOF_LOCAL
    exec zsh

Commit dotfile changes:
  cd ~/dotfiles
  git status
  git add zsh/.zshrc nvim/.config/nvim scripts README.md
  git commit -m "Update dotfiles"
  git push

MSG

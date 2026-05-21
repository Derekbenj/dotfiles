#!/usr/bin/env bash
set -euo pipefail

# Installs Derek's preferred baseline dev tools on Ubuntu/Debian/Distrobox.
# Includes:
#   zsh, git, curl, stow, direnv, zoxide, Node.js/npm,
#   Rust/rustup, uv via Cargo, latest Neovim from official tarball,
#   latest lazygit from GitHub releases, Oh My Zsh, zsh-autosuggestions.

if [[ "${EUID}" -eq 0 ]]; then
  echo "[error] Do not run this script as root. It will use sudo when needed."
  exit 1
fi

have() {
  command -v "$1" >/dev/null 2>&1
}

arch_name() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *)
      echo "[error] Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

install_apt_baseline() {
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
      tar \
      gzip \
      ripgrep \
      fd-find \
      nodejs \
      npm
  else
    echo "[warn] apt-get not found. Install baseline packages manually for this OS."
  fi

  if have fdfind && ! have fd; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

install_latest_nvim() {
  local arch url tmpdir extracted
  arch="$(arch_name)"

  if [[ "$arch" == "x86_64" ]]; then
    url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
  else
    url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
  fi

  echo "[nvim] Installing latest Neovim release from:"
  echo "       $url"

  tmpdir="$(mktemp -d)"
  curl -fL "$url" -o "$tmpdir/nvim.tar.gz"
  tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"

  extracted="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d -name 'nvim*' | head -n 1)"

  if [[ -z "$extracted" || ! -x "$extracted/bin/nvim" ]]; then
    echo "[error] Neovim archive did not contain expected bin/nvim."
    find "$tmpdir" -maxdepth 3 -print
    rm -rf "$tmpdir"
    exit 1
  fi

  sudo mkdir -p /opt
  sudo rm -rf /opt/nvim
  sudo cp -a "$extracted" /opt/nvim

  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/vim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/vi

  rm -rf "$tmpdir"
  hash -r 2>/dev/null || true

  echo "[nvim] Installed: $(/usr/local/bin/nvim --version | head -n 1)"
}

install_latest_lazygit() {
  if have lazygit; then
    echo "[lazygit] Already installed: $(lazygit --version | head -n 1)"
    return
  fi

  local arch lg_arch tmpdir version url
  arch="$(arch_name)"

  if [[ "$arch" == "x86_64" ]]; then
    lg_arch="x86_64"
  else
    lg_arch="arm64"
  fi

  echo "[lazygit] Installing latest lazygit release..."

  tmpdir="$(mktemp -d)"
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name":\s*"v\K[^"]+' | head -n 1 || true)"

  if [[ -z "$version" ]]; then
    echo "[warn] Could not determine latest lazygit version; skipping lazygit."
    rm -rf "$tmpdir"
    return
  fi

  url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${lg_arch}.tar.gz"
  curl -fL "$url" -o "$tmpdir/lazygit.tar.gz"
  tar -xzf "$tmpdir/lazygit.tar.gz" -C "$tmpdir"

  if [[ ! -x "$tmpdir/lazygit" ]]; then
    echo "[warn] lazygit archive did not contain executable; skipping lazygit."
    find "$tmpdir" -maxdepth 2 -print
    rm -rf "$tmpdir"
    return
  fi

  sudo install -m 0755 "$tmpdir/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmpdir"
  echo "[lazygit] Installed: $(lazygit --version | head -n 1)"
}

install_rust_and_uv() {
  if ! have rustup && ! have cargo; then
    echo "[rust] Installing Rust with rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  else
    echo "[rust] Rust/Cargo already installed."
  fi

  if [[ -r "$HOME/.cargo/env" ]]; then
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
    echo "[warn] cargo still not found, so uv was not installed."
  fi
}

install_oh_my_zsh() {
  local omz_dir zsh_custom
  omz_dir="${DOTFILES_OMZ_DIR:-$HOME/.oh-my-zsh}"

  if [[ -d "$omz_dir" ]]; then
    echo "[omz] Oh My Zsh already installed at $omz_dir."
  else
    echo "[omz] Installing Oh My Zsh to $omz_dir without changing shell immediately..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$omz_dir" \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  zsh_custom="${ZSH_CUSTOM:-$omz_dir/custom}"

  if [[ -d "$omz_dir" && ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    echo "[omz] Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
  else
    echo "[omz] zsh-autosuggestions already installed or Oh My Zsh missing."
  fi
}

set_default_zsh_if_possible() {
  if ! have zsh; then
    echo "[warn] zsh was not found."
    return
  fi

  local zsh_path current_login_shell
  zsh_path="$(command -v zsh)"
  current_login_shell="$(getent passwd "$USER" | cut -d: -f7 || true)"

  if [[ "$current_login_shell" != "$zsh_path" ]]; then
    echo "[zsh] Attempting to set login shell to $zsh_path"

    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    if chsh -s "$zsh_path"; then
      echo "[zsh] Login shell changed. Re-enter the container for it to fully apply."
    else
      echo "[warn] chsh failed. In some Distrobox/container setups this is normal."
    fi
  else
    echo "[zsh] zsh is already your login shell."
  fi
}

ensure_temp_zshrc_for_bootstrap() {
  # Suppress zsh-newuser-install before Stow is ready.
  # install.sh will remove this exact placeholder before stowing zsh.
  if [[ ! -e "$HOME/.zshrc" ]]; then
    echo "# Temporary .zshrc created by bootstrap; replaced by stow." > "$HOME/.zshrc"
  fi
}

run_stow_install() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ -x "$script_dir/install.sh" ]]; then
    echo "[dotfiles] Running Stow install..."
    "$script_dir/install.sh"
  else
    echo "[warn] $script_dir/install.sh not found or not executable; skipping Stow install."
  fi
}

print_versions() {
  echo
  echo "[versions]"
  have node && echo "node: $(node --version)"
  have npm && echo "npm:  $(npm --version)"
  have rustc && echo "rust: $(rustc --version)"
  have cargo && echo "cargo: $(cargo --version)"
  have uv && echo "uv:   $(uv --version)"
  have nvim && echo "nvim: $(nvim --version | head -n 1)"
  have lazygit && echo "lazygit: $(lazygit --version | head -n 1)"
}

install_apt_baseline
install_latest_nvim
install_latest_lazygit
install_rust_and_uv
ensure_temp_zshrc_for_bootstrap
install_oh_my_zsh
set_default_zsh_if_possible
run_stow_install
print_versions

cat <<'MSG'

[done] Favorites installed.

Start using zsh now:
  exec zsh

Container prompt tag:
  Enable for this machine/container:
    cat > ~/.zshrc.local <<'EOF'
export DOTFILES_CONTAINER_PROMPT=1
export DOTFILES_CONTAINER_NAME="generic"
EOF
    exec zsh

MSG

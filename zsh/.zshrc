# ~/.zshrc managed by ~/dotfiles via GNU Stow
# Machine-specific/private settings go in ~/.zshrc.local

# Basic PATHs first. /usr/local/bin must come before /usr/bin so the latest
# manually installed Neovim wins over Ubuntu's older apt neovim.
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Rust/Cargo, if installed.
if [[ -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# uv standalone installer path, if installed.
# Some installers create ~/.local/bin/env; only source it if it exists.
if [[ -r "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
elif [[ -r "$HOME/.local/share/../bin/env" ]]; then
  source "$HOME/.local/share/../bin/env"
fi

# Oh My Zsh, if installed. Fall back gracefully on machines/containers without it.
# Do not inherit a stale ZSH path from a parent shell/container.
export ZSH="${DOTFILES_OMZ_DIR:-$HOME/.oh-my-zsh}"
ZSH_THEME="${ZSH_THEME:-robbyrussell}"
plugins=(git zsh-autosuggestions)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz colors && colors
  setopt PROMPT_SUBST
  PROMPT="${PROMPT:-%F{green}%n@%m%f:%F{blue}%~%f %# }"
fi

# direnv, if installed.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# zoxide, if installed.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Handy aliases.
alias dd="distrobox list"
alias de="distrobox enter"

# Local machine/container secrets, PATH additions, prompt overrides, etc.
# This is intentionally sourced before the final prompt marker so local files
# can set DOTFILES_CONTAINER_PROMPT and DOTFILES_CONTAINER_NAME.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# >>> dotfiles container prompt marker >>>
# Enable per machine/container with:
#   export DOTFILES_CONTAINER_PROMPT=1
#
# Optional manual name override:
#   export DOTFILES_CONTAINER_NAME="generic"
#
# This block intentionally belongs at the bottom of .zshrc so it runs
# after Oh My Zsh / themes have already built the prompt.
if [[ "${DOTFILES_CONTAINER_PROMPT:-0}" == "1" ]] && [[ -n "${container:-}" || -f /run/.containerenv || -f /.dockerenv ]]; then
  if [[ -n "${DOTFILES_CONTAINER_NAME:-}" ]]; then
    _dotfiles_container_name="$DOTFILES_CONTAINER_NAME"
  elif [[ -n "${DISTROBOX_NAME:-}" ]]; then
    _dotfiles_container_name="$DISTROBOX_NAME"
  elif [[ -r /run/.containerenv ]] && grep -q '^name=' /run/.containerenv 2>/dev/null; then
    _dotfiles_container_name="$(grep '^name=' /run/.containerenv | head -n1 | cut -d= -f2- | tr -d '"')"
  elif [[ -n "${container:-}" && "${container:-}" != "podman" && "${container:-}" != "docker" ]]; then
    _dotfiles_container_name="$container"
  else
    _dotfiles_container_name="container"
  fi

  PROMPT="[${_dotfiles_container_name}:distrobox] ${PROMPT:-%n@%m:%~ %# }"
  unset _dotfiles_container_name
fi
# <<< dotfiles container prompt marker <<<

# ~/.zshrc managed by ~/dotfiles via GNU Stow
# Machine-specific/private settings go in ~/.zshrc.local

# Basic PATHs first. Keep these safe even on fresh machines/containers.
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Optional distrobox/container prompt marker.
# Enable with: export DOTFILES_CONTAINER_PROMPT=1
# Disable with: unset DOTFILES_CONTAINER_PROMPT
if [[ "${DOTFILES_CONTAINER_PROMPT:-0}" == "1" ]] && [[ -n "${container:-}" || -f /run/.containerenv || -f /.dockerenv ]]; then
  _dotfiles_container_name="${DISTROBOX_NAME:-${container:-container}}"
  # Put the tag in front of whatever prompt/theme is active.
  export PROMPT="[${_dotfiles_container_name}:distrobox] ${PROMPT:-%n@%m:%~ %# }"
fi

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
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
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
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

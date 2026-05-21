# Derek's shared zsh config.
# Keep machine/container-specific settings in ~/.zshrc.local.

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space

[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="${ZSH_THEME:-robbyrussell}"

plugins=(git)

if [[ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]]; then
  plugins+=(zsh-autosuggestions)
fi

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz colors && colors
  PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# >>> dotfiles container prompt marker >>>
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

  PROMPT="[${_dotfiles_container_name}:distrobox] ${PROMPT}"
  unset _dotfiles_container_name
fi
# <<< dotfiles container prompt marker <<<

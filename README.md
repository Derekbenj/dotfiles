# dotfiles

Personal dotfiles managed with GNU Stow.

## Install in a fresh Ubuntu/Debian/Distrobox container

```bash
cd ~
git clone git@github.com:Derekbenj/dotfiles.git
cd dotfiles
./scripts/install_favorites.sh
exec zsh
```

This installs baseline tools, the latest official Neovim Linux binary, Rust, uv, Oh My Zsh, npm, and then symlinks the dotfiles with Stow.

## Stow-only reinstall

```bash
cd ~/dotfiles
./scripts/install.sh
```

## Container prompt tag

For a container named `generic`:

```bash
cat > ~/.zshrc.local <<'EOF_LOCAL'
export DOTFILES_CONTAINER_PROMPT=1
export DOTFILES_CONTAINER_NAME="generic"
EOF_LOCAL
exec zsh
```

## Commit changes

```bash
cd ~/dotfiles
git status
git add zsh/.zshrc nvim/.config/nvim scripts README.md
git commit -m "Update dotfiles"
git push
```

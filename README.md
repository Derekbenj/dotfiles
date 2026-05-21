# dotfiles

Stow-style dotfiles.

## Fresh container install

```bash
git clone git@github.com:Derekbenj/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/install_favorites.sh
```

## Re-stow only

```bash
cd ~/dotfiles
./scripts/install.sh
```

## Enable container prompt

```bash
cat > ~/.zshrc.local <<'EOF'
export DOTFILES_CONTAINER_PROMPT=1
export DOTFILES_CONTAINER_NAME="generic"
EOF
exec zsh
```

# dotfiles

Personal dotfiles managed with GNU Stow.

## Layout

```text
dotfiles/
├── nvim/.config/nvim/   # becomes ~/.config/nvim
├── zsh/.zshrc           # becomes ~/.zshrc
└── scripts/
```

## First install on Ubuntu/Debian/Distrobox

```bash
cd ~/dotfiles
./scripts/install_favorites.sh
```

This installs baseline tools with `apt`, installs Rust using rustup, installs `uv` using Cargo, installs Oh My Zsh, installs the `zsh-autosuggestions` plugin, attempts to make zsh your default shell, and then runs the Stow install.

The Rust install command used is:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

`uv` is installed with:

```bash
cargo install uv
```

Note: the official uv docs currently recommend the standalone installer as the primary install path, but this repo intentionally uses Cargo because this setup prefers installing it via Rust.

## Stow only

If the tools are already installed:

```bash
cd ~/dotfiles
./scripts/install.sh
```

That runs:

```bash
stow --target="$HOME" --restow nvim zsh
```

## Container prompt tag

The tracked `.zshrc` can show a Distrobox/container tag like:

```text
[generic:distrobox]
```

Enable it per machine/container:

```bash
echo 'export DOTFILES_CONTAINER_PROMPT=1' >> ~/.zshrc.local
source ~/.zshrc
```

Disable it:

```bash
sed -i '/DOTFILES_CONTAINER_PROMPT/d' ~/.zshrc.local
source ~/.zshrc
```

The container name comes from `$DISTROBOX_NAME` when available, then `$container`, then falls back to `container`.

## Machine-specific config

Do not commit secrets or one-machine-only paths. Put them here instead:

```bash
~/.zshrc.local
```

Examples:

```bash
export OPENAI_API_KEY="..."
export DOTFILES_CONTAINER_PROMPT=1
export PATH="$HOME/some-local-tool/bin:$PATH"
```

## Editing and committing

After Stow, `~/.zshrc` is a symlink to `~/dotfiles/zsh/.zshrc`. Editing either path edits the tracked file.

```bash
nvim ~/.zshrc
cd ~/dotfiles
git status
git add zsh/.zshrc
git commit -m "Update zsh config"
git push
```

On another machine:

```bash
cd ~/dotfiles
git pull
./scripts/install.sh
```

Usually `git pull` is enough for already-stowed files, but re-running the install script is safe.

## Oh My Zsh not installed?

The `.zshrc` is defensive. If `~/.oh-my-zsh/oh-my-zsh.sh` exists, it loads Oh My Zsh. If not, it falls back to a simple prompt instead of breaking your shell.

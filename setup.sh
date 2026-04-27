#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Installing brew packages from Brewfile..."
brew bundle --file="$DOTFILES/homebrew/.Brewfile"

echo "==> Stowing configs..."
cd "$DOTFILES"
for pkg in ghostty nvim tmux zsh karabiner; do
  echo "  -> $pkg"
  stow --restow --target="$HOME" "$pkg"
done

echo "==> Done."

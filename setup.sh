#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

"$DOTFILES/setup-brew.sh"
"$DOTFILES/setup-stow.sh"

echo "==> Done."

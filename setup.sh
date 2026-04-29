#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

"$DOTFILES/setup-package.sh"
"$DOTFILES/setup-config.sh"

echo "==> Done."

#!/usr/bin/env bash
set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
  echo "==> Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# TPM's CLI reads the plugin directory from a running tmux server. Use a
# temporary server without loading the config, which references plugins that
# may not exist yet. Leave any interactive tmux server and sessions untouched.
echo "==> Installing tmux plugins..."
SETUP_SERVER="dotfiles-setup-$$"
unset TMUX
trap 'tmux -L "$SETUP_SERVER" kill-server 2>/dev/null || true' EXIT
tmux -L "$SETUP_SERVER" -f /dev/null new-session -d -s setup
export TMUX="$(tmux -L "$SETUP_SERVER" display-message -p '#{socket_path}'),0,0"
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
"$TPM_DIR/bin/install_plugins"

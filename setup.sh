#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
BACKUP_TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$DOTFILES/backups/$BACKUP_TS"
MANIFEST="$BACKUP_DIR/manifest.jsonl"

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

write_manifest_header() {
  [ -f "$MANIFEST" ] && return
  mkdir -p "$BACKUP_DIR"
  local commit
  commit=$(git -C "$DOTFILES" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  jq -nc \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg dotfiles_commit "$commit" \
    --arg host "$(hostname -s)" \
    '{_meta:true, version:1, created_at:$created_at, dotfiles_commit:$dotfiles_commit, host:$host}' \
    >> "$MANIFEST"
}

backup_one() {
  local pkg="$1" rel="$2"
  local src="$HOME/$rel"
  local backup_rel="$pkg/$rel"
  local dst="$BACKUP_DIR/$backup_rel"

  write_manifest_header

  local kind symlink_to=""
  if [ -L "$src" ]; then
    kind="symlink"
    symlink_to="$(readlink "$src")"
    rm "$src"
  elif [ -d "$src" ]; then
    kind="dir"
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
  else
    kind="file"
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
  fi

  local mode=""
  [ "$kind" != "symlink" ] && mode=$(stat -f '%Lp' "$dst" 2>/dev/null || echo "")

  if [ "$kind" = "symlink" ]; then
    jq -nc \
      --arg pkg "$pkg" --arg target "$rel" \
      --arg kind "$kind" --arg symlink_to "$symlink_to" \
      '{pkg:$pkg, target:$target, backup:null, kind:$kind, symlink_to:$symlink_to}' \
      >> "$MANIFEST"
  else
    jq -nc \
      --arg pkg "$pkg" --arg target "$rel" \
      --arg backup "$backup_rel" --arg kind "$kind" --arg mode "$mode" \
      '{pkg:$pkg, target:$target, backup:$backup, kind:$kind, mode:$mode}' \
      >> "$MANIFEST"
  fi

  echo "    backed up: ~/$rel ($kind)"
}

stow_pkg() {
  local pkg="$1"
  local dry
  if dry=$(stow --no --restow --target="$HOME" "$pkg" 2>&1); then
    stow --restow --target="$HOME" "$pkg"
    return
  fi

  local conflicts
  conflicts=$(printf '%s\n' "$dry" \
    | sed -nE '
        s/^[[:space:]]*\* cannot stow .+ over existing target (.+) since .*$/\1/p
        s/^[[:space:]]*\* existing target is [^:]+: (.+)$/\1/p
      ' \
    | sed -E 's/ =>.*$//')

  if [ -z "$conflicts" ]; then
    printf '%s\n' "$dry" >&2
    return 1
  fi

  echo "  ! Conflicts for $pkg:"
  while IFS= read -r f; do echo "    - ~/$f"; done <<<"$conflicts"
  printf "  Move these to %s and continue? [y/N] " "${BACKUP_DIR/#$HOME/~}"
  local ans
  read -r ans </dev/tty
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "  Skipping $pkg."
    return 0
  fi

  while IFS= read -r f; do
    backup_one "$pkg" "$f"
  done <<<"$conflicts"

  stow --restow --target="$HOME" "$pkg"
}

echo "==> Stowing configs..."
cd "$DOTFILES"
for pkg in ghostty nvim tmux zsh karabiner starship; do
  echo "  -> $pkg"
  stow_pkg "$pkg"
done

echo "==> Done."

#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
BACKUP_TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$DOTFILES/backups/$BACKUP_TS"
MANIFEST="$BACKUP_DIR/manifest.jsonl"

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
for pkg in ghostty nvim tmux zsh starship; do
  echo "  -> $pkg"
  stow_pkg "$pkg"
done

# Karabiner-Elements rewrites karabiner.json with an atomic rename on every GUI
# save, which replaces a file-level symlink with a real file and silently breaks
# stow's tracking. It also auto-creates assets/ and automatic_backups/ inside
# ~/.config/karabiner, which prevents stow from folding the directory. Bypass
# stow and link the directory itself so the rename stays inside the linked dir.
echo "  -> karabiner (direct symlink)"
karabiner_src="$DOTFILES/karabiner/.config/karabiner"
karabiner_dst="$HOME/.config/karabiner"
mkdir -p "$HOME/.config"

# Clean up symlink misplaced inside the target dir by a prior broken run.
if [ -L "$karabiner_dst/karabiner" ] && [ "$(readlink "$karabiner_dst/karabiner")" = "$karabiner_src" ]; then
  rm "$karabiner_dst/karabiner"
fi

if [ -L "$karabiner_dst" ]; then
  ln -sfn "$karabiner_src" "$karabiner_dst"
elif [ -d "$karabiner_dst" ]; then
  echo "  ! ~/.config/karabiner is a real directory; ln would place the link inside it."
  printf "  Move it to %s and link? [y/N] " "${BACKUP_DIR/#$HOME/~}"
  read -r ans </dev/tty
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    backup_one "karabiner" ".config/karabiner"
    ln -s "$karabiner_src" "$karabiner_dst"
  else
    echo "  Skipping karabiner."
  fi
else
  ln -s "$karabiner_src" "$karabiner_dst"
fi
unset karabiner_src karabiner_dst

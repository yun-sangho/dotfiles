#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
BACKUPS_ROOT="$DOTFILES/backups"

usage() {
  cat <<EOF
Usage: restore.sh [--list | --dry-run | --yes] [<timestamp>|latest] [<pkg>...]

  --list                List available backup timestamps and their packages.
  --dry-run             Show what would be restored without changing anything.
  -y, --yes             Skip confirmation prompt.
  <timestamp>           A directory under backups/ (e.g. 20260429-171102).
                        Defaults to "latest" (most recent).
  <pkg>...              Restrict restoration to specific packages.

Examples:
  restore.sh
  restore.sh --list
  restore.sh latest nvim tmux
  restore.sh 20260429-171102
  restore.sh --dry-run latest
EOF
}

DRY_RUN=0
LIST_ONLY=0
ASSUME_YES=0
TS=""
PKGS=()

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --list) LIST_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    -*) echo "unknown flag: $arg" >&2; usage >&2; exit 2 ;;
    *)
      if [ -z "$TS" ]; then
        TS="$arg"
      else
        PKGS+=("$arg")
      fi
      ;;
  esac
done

list_timestamps() {
  [ -d "$BACKUPS_ROOT" ] || return 0
  find "$BACKUPS_ROOT" -mindepth 1 -maxdepth 1 -type d \
    | sed -E "s|^$BACKUPS_ROOT/||" \
    | sort -r
}

resolve_ts() {
  local raw="$1"
  if [ -z "$raw" ] || [ "$raw" = "latest" ]; then
    list_timestamps | head -1
  else
    echo "$raw"
  fi
}

if [ "$LIST_ONLY" = "1" ]; then
  if [ ! -d "$BACKUPS_ROOT" ]; then
    echo "No backups directory at $BACKUPS_ROOT"
    exit 0
  fi
  found=0
  while IFS= read -r ts; do
    [ -z "$ts" ] && continue
    found=1
    local_manifest="$BACKUPS_ROOT/$ts/manifest.jsonl"
    if [ -f "$local_manifest" ]; then
      pkgs=$(jq -r 'select(._meta != true) | .pkg' "$local_manifest" | sort -u | paste -sd, -)
      meta=$(jq -r 'select(._meta == true) | "commit=\(.dotfiles_commit) host=\(.host)"' "$local_manifest")
      echo "$ts  [$pkgs]  ($meta)"
    else
      echo "$ts  (no manifest)"
    fi
  done < <(list_timestamps)
  [ "$found" = "0" ] && echo "No backups found."
  exit 0
fi

TS="$(resolve_ts "$TS")"
if [ -z "$TS" ]; then
  echo "No backups found in $BACKUPS_ROOT" >&2
  exit 1
fi

BACKUP_DIR="$BACKUPS_ROOT/$TS"
MANIFEST="$BACKUP_DIR/manifest.jsonl"

if [ ! -f "$MANIFEST" ]; then
  echo "Manifest not found: $MANIFEST" >&2
  exit 1
fi

# Build a jq filter that selects entries (excludes meta/restored markers)
# and optionally filters by package.
if [ ${#PKGS[@]} -gt 0 ]; then
  pkg_filter=$(printf '"%s",' "${PKGS[@]}")
  pkg_filter="[${pkg_filter%,}]"
  JQ_FILTER='select(.pkg != null) | select(.pkg as $p | '"$pkg_filter"' | index($p))'
else
  JQ_FILTER='select(.pkg != null)'
fi

# Collect distinct packages we'll touch (for stow -D).
TOUCH_PKGS=()
while IFS= read -r line; do
  [ -n "$line" ] && TOUCH_PKGS+=("$line")
done < <(jq -r "$JQ_FILTER | .pkg" "$MANIFEST" | sort -u)

if [ ${#TOUCH_PKGS[@]} -eq 0 ]; then
  echo "Nothing to restore (no matching entries in $MANIFEST)."
  exit 0
fi

echo "Backup:    $TS"
echo "Packages:  ${TOUCH_PKGS[*]}"
echo "Manifest:  $MANIFEST"
[ "$DRY_RUN" = "1" ] && echo "Mode:      DRY RUN"
echo

# Show plan
jq -r "$JQ_FILTER"' | "  [\(.pkg)] \(.kind)\t~/\(.target)"' "$MANIFEST" | column -t -s$'\t'
echo

if [ "$DRY_RUN" = "1" ]; then
  exit 0
fi

if [ "$ASSUME_YES" != "1" ]; then
  printf "Proceed with restore? This will unstow listed packages and move backups back into place. [y/N] "
  read -r ans </dev/tty
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# 1. Unstow each affected package so the dotfiles symlinks are removed.
cd "$DOTFILES"
for pkg in "${TOUCH_PKGS[@]}"; do
  if [ -d "$DOTFILES/$pkg" ]; then
    echo "  unstow: $pkg"
    stow -D --target="$HOME" "$pkg" 2>/dev/null || true
  fi
done

# 2. Restore each entry from the manifest.
while IFS= read -r entry; do
  kind=$(jq -r '.kind' <<<"$entry")
  target=$(jq -r '.target' <<<"$entry")
  dst="$HOME/$target"

  case "$kind" in
    file|dir)
      backup_rel=$(jq -r '.backup' <<<"$entry")
      src="$BACKUP_DIR/$backup_rel"
      if [ ! -e "$src" ]; then
        echo "    skip (already restored): ~/$target"
        continue
      fi
      [ -e "$dst" ] || [ -L "$dst" ] && rm -rf "$dst"
      mkdir -p "$(dirname "$dst")"
      mv "$src" "$dst"
      mode=$(jq -r '.mode // empty' <<<"$entry")
      [ -n "$mode" ] && chmod "$mode" "$dst"
      echo "    restored ($kind): ~/$target"
      ;;
    symlink)
      [ -e "$dst" ] || [ -L "$dst" ] && rm -rf "$dst"
      mkdir -p "$(dirname "$dst")"
      symlink_to=$(jq -r '.symlink_to' <<<"$entry")
      ln -sfn "$symlink_to" "$dst"
      echo "    restored (symlink): ~/$target -> $symlink_to"
      ;;
    *)
      echo "  ! unknown kind: $kind for ~/$target" >&2
      ;;
  esac
done < <(jq -c "$JQ_FILTER" "$MANIFEST")

# 3. Mark manifest as restored (append marker line). Do not modify originals.
jq -nc \
  --arg restored_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson pkgs "$(printf '%s\n' "${TOUCH_PKGS[@]}" | jq -R . | jq -sc .)" \
  '{_restored:true, restored_at:$restored_at, pkgs:$pkgs}' \
  >> "$MANIFEST"

# 4. Clean empty package dirs in the backup. Keep manifest + non-empty dirs.
for pkg in "${TOUCH_PKGS[@]}"; do
  pkg_dir="$BACKUP_DIR/$pkg"
  [ -d "$pkg_dir" ] && find "$pkg_dir" -depth -type d -empty -delete 2>/dev/null || true
done

echo
echo "Restore complete."

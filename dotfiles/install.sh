#!/bin/bash
set -euo pipefail

DIR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_TARGET="$HOME"

# Files installed to $HOME with the same name (source name == target name).
FILES=(.bashrc .bash_profile .profile .gitconfig .tmux.conf .vimrc)

# Files with a custom destination path (relative to $HOME): "source:dest".
CUSTOM=("kitty.conf:.config/kitty/kitty.conf")

# Timestamped backup dir; only created if we actually back something up.
BACKUP_DIR="$DIR_TARGET/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

install_file() {
    local src="$1" dst="$2" backup_name="$3"
    [ -f "$src" ] || { echo "skip: $(basename "$src") (not in repo)"; return; }
    mkdir -p "$(dirname "$dst")"
    # Back up an existing target only if it differs from what we install.
    if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
        mkdir -p "$(dirname "$BACKUP_DIR/$backup_name")"
        cp "$dst" "$BACKUP_DIR/$backup_name"
    fi
    cp "$src" "$dst"
}

for f in "${FILES[@]}"; do
    install_file "$DIR_SOURCE/$f" "$DIR_TARGET/$f" "$f"
done

for entry in "${CUSTOM[@]}"; do
    src_name="${entry%%:*}"
    rel_dst="${entry#*:}"
    install_file "$DIR_SOURCE/$src_name" "$DIR_TARGET/$rel_dst" "$rel_dst"
done

[ -d "$BACKUP_DIR" ] && echo "Existing dotfiles backed up to: $BACKUP_DIR"
echo "Dotfiles installed. Re-login to apply shell changes."

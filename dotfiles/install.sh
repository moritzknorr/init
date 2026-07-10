#!/bin/bash
DIR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_TARGET="/home/knorr"
cp "$DIR_SOURCE/.bashrc" "$DIR_TARGET/.bashrc"
cp "$DIR_SOURCE/.bash_profile" "$DIR_TARGET/.bash_profile"
cp "$DIR_SOURCE/.profile" "$DIR_TARGET/.profile"
cp "$DIR_SOURCE/.gitconfig" "$DIR_TARGET/.gitconfig"
cp "$DIR_SOURCE/.tmux.conf" "$DIR_TARGET/.tmux.conf"
cp "$DIR_SOURCE/.vimrc" "$DIR_TARGET/.vimrc"

# Ranger
mkdir -p "$DIR_TARGET/.config/ranger"
cp "$DIR_SOURCE/ranger/rc.conf"      "$DIR_TARGET/.config/ranger/rc.conf"
cp "$DIR_SOURCE/ranger/rifle.conf"   "$DIR_TARGET/.config/ranger/rifle.conf"
cp "$DIR_SOURCE/ranger/commands.py"  "$DIR_TARGET/.config/ranger/commands.py"
cp "$DIR_SOURCE/ranger/scope.sh"     "$DIR_TARGET/.config/ranger/scope.sh"
chmod +x "$DIR_TARGET/.config/ranger/scope.sh"

echo "Dotfiles installed. Re-login to apply shell changes."

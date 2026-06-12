#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$DIR/.bashrc" ~/.bashrc
cp "$DIR/.bash_profile" ~/.bash_profile
cp "$DIR/.profile" ~/.profile
cp "$DIR/.gitconfig" ~/.gitconfig
cp "$DIR/.tmux.conf" ~/.tmux.conf
cp "$DIR/.vimrc" ~/.vimrc
echo "Dotfiles installed. Re-login to apply shell changes."

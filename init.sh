#!/bin/sh
# DEV Utilities
echo "Installinc Xcode CLI Tools"
xcode-select --install

# VARIABLES
DOTFILES_DIR"/Projects/Dotfiles"

# Installing Homebrew
echo "Installing Homebrew"
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew update
echo "installing Homevrew Packages"
brew tap homebrew/bundle
brew bundle

# Cloning Dotfiles
echo "Cloning Dotfiles"
git clone https://github.com/Ehrax/dotfiles "$HOME_DIR/$DOTFILES_DIR"

# Setting Up Dev Utilites
echo "Configurating Fish Shell & Starship"

echo "Installing Java8"

echo "Installing Node Verions"

echo "Configurating TMUX Settings"
ln -s "$HOME/$DOTFILES_DIR/tmux.conf" "$HOME_DIR/.tmux.conf"

echo "Configurating up NeoVIM"
ln -s "$HOME/$DOTFILES_DIR/nvim.vim" "$HOME_DIR/.config/nvim/init.vim"

echo "Configurating Git"
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
git config --global alias.tree "log --graph --full-history --all --color --date=short --pretty=format:'%Cred%x09%h %Creset%ad%Cblue%d %Creset %s %C(bold)(%an)%Creset'"
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global interactive.diffFilter "diff-so-fancy --patch"

# System Utilities

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

# Setting Up Dev Utilities
echo "Installing Fish Shell & Starship"
ln -s "$HOME/$DOTFILES_DIR/config.fish" "$HOME/.config/fish/config.fish"

echo /usr/local/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/local/bin/fish

echo "Installing Java8"

echo "Installing nvm"

echo "Installing up NeoVIM"

echo "Configurating Git"
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
git config --global alias.tree "log --graph --full-history --all --color --date=short --pretty=format:'%Cred%x09%h %Creset%ad%Cblue%d %Creset %s %C(bold)(%an)%Creset'"
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global interactive.diffFilter "diff-so-fancy --patch"

# System Utilities
echo "Setting up khd"
ln -s "$HOME/$DOTFILES_DIR/khdrc" "$HOME/.khdrc"
brew services start khd


#!/bin/bash
# =============================================================================
# Dotfiles Setup Script
# Guided installation for macOS development environment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}===================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}➜${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# =============================================================================
# Check Prerequisites
# =============================================================================

print_header "Checking Prerequisites"

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi
print_success "Running on macOS"

# Check for Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    print_step "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode tools installation, then re-run this script."
    exit 0
fi
print_success "Xcode Command Line Tools installed"

# =============================================================================
# Install Homebrew
# =============================================================================

print_header "Homebrew Setup"

if ! command -v brew &>/dev/null; then
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ -d "/opt/homebrew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        print_error "Homebrew installation directory not found after install."
        exit 1
    fi
else
    print_success "Homebrew already installed"
fi

print_step "Updating Homebrew..."
brew update

# =============================================================================
# Install Packages via Brewfile
# =============================================================================

print_header "Installing Packages"

print_step "Running brew bundle..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

print_success "All packages installed"

# =============================================================================
# Create Symlinks
# =============================================================================

print_header "Creating Symlinks"

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        print_error "Symlink source does not exist, skipping: $source"
        return 1
    fi

    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        local backup="${target}.backup"
        if [[ -e "$backup" ]]; then
            print_warning "Backup already exists at $backup — skipping to avoid overwrite"
        else
            print_warning "Backing up existing $target to $backup"
            mv "$target" "$backup"
        fi
    fi

    if [[ -L "$target" ]]; then
        rm "$target"
    fi

    ln -s "$source" "$target"
    print_success "Linked $target"
}

# Fish shell
mkdir -p "$HOME/.config/fish"
create_symlink "$DOTFILES_DIR/configs/fish/config.fish" "$HOME/.config/fish/config.fish"
create_symlink "$DOTFILES_DIR/configs/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"

# Neovim
create_symlink "$DOTFILES_DIR/configs/nvim" "$HOME/.config/nvim"

# Starship
create_symlink "$DOTFILES_DIR/configs/starship/starship.toml" "$HOME/.config/starship.toml"

# Ghostty (macOS path)
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
create_symlink "$DOTFILES_DIR/configs/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

# Lazygit
mkdir -p "$HOME/.config/lazygit"
create_symlink "$DOTFILES_DIR/configs/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

# Git
create_symlink "$DOTFILES_DIR/configs/git/config" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/configs/git/ignore" "$HOME/.gitignore"

# Tmux
mkdir -p "$HOME/.config/tmux"
create_symlink "$DOTFILES_DIR/configs/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
create_symlink "$DOTFILES_DIR/configs/tmux/gitmux.conf" "$HOME/.config/tmux/gitmux.conf"

# Claude Code (shared settings, statusline, skills, and plugins)
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.claude-work"
mkdir -p "$HOME/.claude/plugins"  # ensure personal plugins dir exists before work symlink

create_symlink "$DOTFILES_DIR/configs/claude/settings.json" "$HOME/.claude/settings.json"
create_symlink "$DOTFILES_DIR/configs/claude/settings.json" "$HOME/.claude-work/settings.json"
create_symlink "$DOTFILES_DIR/configs/claude/statusline.sh" "$HOME/.claude/statusline.sh"
create_symlink "$DOTFILES_DIR/configs/claude/mcp.json" "$HOME/.claude/mcp.json"
create_symlink "$DOTFILES_DIR/configs/claude/mcp.json" "$HOME/.claude-work/mcp.json"

# Skills and plugins (shared across both profiles)
create_symlink "$DOTFILES_DIR/configs/claude/skills" "$HOME/.claude/skills"
create_symlink "$HOME/.claude/plugins" "$HOME/.claude-work/plugins"
create_symlink "$HOME/.claude/skills"  "$HOME/.claude-work/skills"

# =============================================================================
# Shell Setup
# =============================================================================

print_header "Shell Setup"

# Get the correct fish path
if [[ -d "/opt/homebrew" ]]; then
    FISH_PATH="/opt/homebrew/bin/fish"
else
    FISH_PATH="/usr/local/bin/fish"
fi

# Add fish to allowed shells if not already there
if ! grep -q "$FISH_PATH" /etc/shells; then
    print_step "Adding Fish to allowed shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# Change default shell to fish
if [[ "$SHELL" != "$FISH_PATH" ]]; then
    if ask_yes_no "Set Fish as your default shell?"; then
        chsh -s "$FISH_PATH"
        print_success "Default shell changed to Fish"
    fi
fi

# Install Fisher plugins
print_step "Installing Fisher plugins..."
if ! fish -c "fisher update"; then
    print_warning "fisher update failed, attempting fresh Fisher install..."
    if ! fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"; then
        print_error "Failed to install Fisher plugins. Run manually: fish -c 'fisher update'"
    fi
fi

# Install TPM (Tmux Plugin Manager)
if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
    print_step "Installing TPM (Tmux Plugin Manager)..."
    if git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"; then
        print_success "TPM installed"
    else
        print_error "Failed to clone TPM. Check your network or install manually: git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm"
    fi
else
    print_success "TPM already installed"
fi

# =============================================================================
# Optional: Development Setup
# =============================================================================

print_header "Development Environment Setup"

# Flutter Setup
if ask_yes_no "Set up Flutter development environment?"; then
    print_step "Setting up Flutter with FVM..."

    # Install Flutter via FVM
    if command -v fvm &>/dev/null; then
        fvm install stable
        fvm global stable
        print_success "Flutter installed via FVM"
    else
        print_warning "fvm not found in PATH. Flutter was not configured. You may need to open a new terminal and re-run."
    fi

    # Print Xcode instructions
    echo ""
    print_warning "For iOS development, you also need:"
    echo "  1. Install Xcode from the App Store"
    echo "  2. Run: sudo xcodebuild -license accept"
    echo "  3. Run: sudo xcodebuild -runFirstLaunch"
    echo "  4. Open Android Studio and complete SDK setup"
    echo ""
fi

# Ruby Setup
if ask_yes_no "Set up Ruby development environment?"; then
    print_step "Setting up Ruby with rbenv..."

    if command -v rbenv &>/dev/null; then
        # Install latest stable Ruby
        RUBY_VERSION=$(rbenv install -l | grep -v - | tail -1 | tr -d ' ')
        rbenv install "$RUBY_VERSION" --skip-existing
        rbenv global "$RUBY_VERSION"

        # Install CocoaPods
        print_step "Installing CocoaPods..."
        gem install cocoapods

        print_success "Ruby $RUBY_VERSION installed with CocoaPods"
    else
        print_warning "rbenv not found in PATH. Ruby was not configured. You may need to open a new terminal and re-run."
    fi
fi

# Node Setup
if ask_yes_no "Set up Node.js development environment?"; then
    print_step "Setting up Node.js with fnm..."

    if command -v fnm &>/dev/null; then
        # Install LTS version
        fnm install --lts
        fnm default lts-latest
        print_success "Node.js LTS installed"
    else
        print_warning "fnm not found in PATH. Node was not configured. You may need to open a new terminal and re-run."
    fi
fi

# =============================================================================
# macOS Configuration
# =============================================================================

print_header "macOS Configuration"

if ask_yes_no "Apply recommended macOS settings? (keyboard, sounds, finder)"; then
    bash "$DOTFILES_DIR/scripts/macos.sh"
fi

# =============================================================================
# Finish
# =============================================================================

print_header "Setup Complete!"

echo "Your development environment is ready!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec fish)"
echo "  2. Open Neovim and let LazyVim install plugins"
echo "  3. Configure Android Studio SDK paths if using Flutter"
echo ""
echo "Useful commands:"
echo "  - lg          : Open Lazygit"
echo "  - v / vim     : Open Neovim"
echo "  - t           : Start tmux"
echo "  - ta <name>   : Attach to tmux session"
echo "  - reload      : Reload Fish config"
echo ""

print_success "Happy coding!"

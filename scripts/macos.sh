#!/bin/bash
# =============================================================================
# macOS System Configuration
# Run this script to configure macOS for development
# =============================================================================

set -e

echo "Configuring macOS settings..."

# =============================================================================
# Keyboard Settings (CRITICAL for Vim!)
# =============================================================================

echo "  Setting keyboard preferences..."

# Disable press-and-hold for keys (enables key repeat - essential for Vim)
defaults write -g ApplePressAndHoldEnabled -bool false

# Fast key repeat rate (lower = faster)
defaults write -g InitialKeyRepeat -int 12  # Normal minimum is 15 (225ms)
defaults write -g KeyRepeat -int 2          # Normal minimum is 2 (30ms)

# =============================================================================
# Disable System Sounds
# =============================================================================

echo "  Disabling system sounds..."

# Mute alert/beep volume
defaults write com.apple.systemsound 'com.apple.sound.beep.volume' -float 0.0

# Disable UI sound effects
defaults write com.apple.systemsound 'com.apple.sound.uiaudio.enabled' -int 0

# Disable volume change feedback
defaults write -g 'com.apple.sound.beep.feedback' -int 0

# =============================================================================
# Finder Settings
# =============================================================================

echo "  Configuring Finder..."

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show Library folder
chflags nohidden ~/Library

# Show /Volumes folder
sudo chflags nohidden /Volumes

# =============================================================================
# Text Input Settings
# =============================================================================

echo "  Configuring text input..."

# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart quotes (annoying in code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# =============================================================================
# Dock Settings
# =============================================================================

echo "  Configuring Dock..."

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Faster Dock auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Faster Dock animation
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# =============================================================================
# Screenshots
# =============================================================================

echo "  Configuring screenshots..."

# Save screenshots to Downloads
defaults write com.apple.screencapture location -string "${HOME}/Downloads"

# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# =============================================================================
# Safari (if used for development)
# =============================================================================

echo "  Configuring Safari dev settings..."

# Enable Safari's Developer menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Enable "Do Not Track"
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# =============================================================================
# Activity Monitor
# =============================================================================

echo "  Configuring Activity Monitor..."

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# =============================================================================
# Apply Changes
# =============================================================================

echo "  Applying changes..."

# Kill affected applications
killall SystemUIServer 2>/dev/null || true
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo ""
echo "macOS configuration complete!"
echo ""
echo "NOTE: Some changes require a logout/restart to take effect:"
echo "  - Keyboard repeat rate settings"
echo "  - Some Finder preferences"
echo ""
echo "Would you like to logout now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    osascript -e 'tell app "System Events" to log out'
fi

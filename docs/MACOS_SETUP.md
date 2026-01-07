# macOS Configuration

The `scripts/macos.sh` script configures macOS for development. Here's what it does and how to customize.

## Keyboard Settings

**Critical for Vim users!**

```bash
# Disable press-and-hold for keys (enables key repeat)
defaults write -g ApplePressAndHoldEnabled -bool false

# Fast key repeat rate
defaults write -g InitialKeyRepeat -int 12  # Default: 15 (225ms)
defaults write -g KeyRepeat -int 2          # Default: 2 (30ms)
```

> Requires logout to take effect.

### Manual Alternative

System Settings → Keyboard → Key repeat rate → Fast
System Settings → Keyboard → Delay until repeat → Short

## System Sounds

```bash
# Mute alert/beep volume
defaults write com.apple.systemsound 'com.apple.sound.beep.volume' -float 0.0

# Disable UI sound effects
defaults write com.apple.systemsound 'com.apple.sound.uiaudio.enabled' -int 0

# Disable volume change feedback
defaults write -g 'com.apple.sound.beep.feedback' -int 0
```

### Manual Alternative

System Settings → Sound → Sound Effects → Alert volume → 0
System Settings → Sound → Sound Effects → Play sound effects → Off

## Text Input

```bash
# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart quotes/dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
```

## Finder

```bash
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable .DS_Store on network/USB
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
```

## Dock

```bash
# Speed up animations
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
```

## Reverting Changes

To revert any setting, use `-bool true` or delete the preference:

```bash
# Example: Re-enable press and hold
defaults write -g ApplePressAndHoldEnabled -bool true

# Or delete the preference entirely
defaults delete -g ApplePressAndHoldEnabled
```

## Apply Changes

After running the script:

```bash
killall SystemUIServer
killall Finder
killall Dock
```

Some settings require a **logout/restart**.

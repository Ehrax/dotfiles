# Flutter Development Setup

Quick guide for setting up Flutter development on macOS.

## Prerequisites

The `init.sh` script installs:
- **FVM** (Flutter Version Manager)
- **Dart** SDK
- **Android Studio**

## Xcode Setup (for iOS Development)

1. **Install Xcode** from the App Store

2. **Accept license and run first launch:**
   ```bash
   sudo xcodebuild -license accept
   sudo xcodebuild -runFirstLaunch
   ```

4. **Install CocoaPods** (via Ruby setup in init.sh):
   ```bash
   gem install cocoapods
   ```

## Android Studio Setup

1. **Open Android Studio** and complete the setup wizard

2. **Install Android SDK** via SDK Manager:
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android SDK (API level for your target)

3. **Configure ANDROID_HOME** (already set in fish config):
   ```
   ~/Library/Android/sdk
   ```

4. **Accept licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

## Using FVM

FVM allows multiple Flutter versions per project.

```bash
# Install a Flutter version
fvm install stable
fvm install 3.19.0

# Set global default
fvm global stable

# Use specific version in project
cd your-project
fvm use 3.19.0

# Run Flutter commands via FVM
fvm flutter run
fvm flutter build

# Or use the fvm spawn shortcut
fvm spawn flutter run
```

## Verify Setup

```bash
flutter doctor -v
```

All checkmarks should be green for your target platforms.

## Common Issues

### CocoaPods not found
```bash
gem install cocoapods
pod setup
```

### Android licenses not accepted
```bash
flutter doctor --android-licenses
```

### Xcode command line tools issue
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

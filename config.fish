# Remove fish default greeting
set --erease fish_greeting

# so our brew install override the commands from the system
set -x PATH /usr/local/sbin $PATH

# Environment Variables
set -x NPM_TOKEN
set -x ANDROID_SDK_ROOT $HOME/Library/Android/sdk
set -x PATH /Applications/Flutter/bin
set -x NVM_DIR

starship init fish | source

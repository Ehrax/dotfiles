# Remove fish default greeting
set --erease fish_greeting

# Enviroment Variables
set -x NPM_TOKEN 
set -x ANDROID_SDK_ROOT $HOME/Library/Android/sdk
set -x PATH /Applications/Flutter/bin
set -x NVM_DIR 


starship init fish | source
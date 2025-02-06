starship init fish | source

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Environment Variables
set -Ua fish_user_paths $HOME/Applications/Flutter/bin
set -Ua fish_user_paths $HOME/.pub-cache/bin
set -Ua fish_user_paths $HOME/.cargo/bin

# set -x ANDROID_SDK_ROOT "$HOME/Library/Android/sdk"

# Jenv
# set -x JENV_ROOT /usr/local/opt/jenv
# set PATH $HOME/.jenv/bin $PATH
# status --is-interactive; and source (jenv init -|psub)

rvm default

fish_ssh_agent

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

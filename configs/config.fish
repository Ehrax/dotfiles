if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Environment Variables
set -Ua fish_user_paths $HOME/Applications/Flutter/bin
# set -x ANDROID_SDK_ROOT "$HOME/Library/Android/sdk"

# Jenv
set -x JENV_ROOT /usr/local/opt/jenv
set PATH $HOME/.jenv/bin $PATH
status --is-interactive; and source (jenv init -|psub)

starship init fish | source

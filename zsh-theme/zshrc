###############################################################################
# PATH
###############################################################################
# NPM TOKEN
export NPM_TOKEN="e0991481-0fd0-437a-95cd-c86f6c65a493"

# Android
export ANDROID_SDK_ROOT="/Users/ehrax/Library/Android/sdk"

# Path to your oh-my-zsh installation.
export ZSH=/Users/ehrax/.oh-my-zsh
# Rvm
export PATH="$PATH:$HOME/.rvm/bin"
# Brew
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"
# Flutter
export PATH="$PATH:$HOME/Applications/Flutter/bin"
# Nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# Cocoapods
export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH
# Jenv
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

###############################################################################
# THEME & PLUGINS
###############################################################################

# Set name of theme to load.
ZSH_THEME="ehrax"

# Add wisely, as too many plugins slow down shell startup.
plugins=(osx git git-flow-avh docker colored-man-pages tmux rails
        brew colorize)

###############################################################################
# User configuration 
###############################################################################

# uncomment following line if you want red dots to be displayed while waitinf for completion
COMPLETION_WAITING_DOTS="false"

# Disable repeating command before result of command
DISABLE_AUTO_TITLE="true"

# ls colors
export CLICOLOR=1

# ENABLE_CORRECTION="true"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

export EDITOR='vim'

source $ZSH/oh-my-zsh.sh

# ls after every cd
function chpwd() {
    emulate -L zsh
    ls
}

# ls on enter
auto-ls () {
    if [[ $#BUFFER -eq 0 ]]; then
        echo ""
        ls
        echo -e "\n"
        zle redisplay
    else
        zle .$WIDGET
    fi
}
zle -N accept-line auto-ls
zle -N other-widget auto-ls

# fuzzy-finder
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

export FZF_TMUX=1
export FZF_TMUX_HEIGHT=10
export FZF_CTRL_R_OPTS="$FZF_DEFAULT_OPTS"

# Add rbenv to bash so that it loads every time you open a terminal
# echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.bash_profile
# source ~/.bash_profile

###############################################################################
# ALIASES
###############################################################################
alias so="source ~/.zshrc"
alias home="cd ~/"
alias vim="nvim"

###############################################################################
# RANDOM
###############################################################################
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

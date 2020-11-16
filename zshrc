###############################################################################
# PATH
###############################################################################

# Path to your oh-my-zsh installation.
export ZSH=/Users/alekei/.oh-my-zsh
# Flutter
export PATH="$PATH:`pwd`/Applications/Flutter/bin"
# NVM
export NVM_DIR=~/.nvm
eval "$(rbenv init -)"
# RVM
export PATH="$PATH:$HOME/.rvm/bin"
source "$(brew --prefix nvm)/nvm.sh"

# Set name of theme to load.
ZSH_THEME="ehrax"

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

###############################################################################
# ALIASES
###############################################################################
alias so="source ~/.zshrc"
alias home="cd ~/"
alias vim="nvim"

###############################################################################
# CUSTOM
###############################################################################
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

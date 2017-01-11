###############################################################################
# PATH
###############################################################################

# Path to your oh-my-zsh installation.
export ZSH=/Users/alexanderrasputin/.oh-my-zsh

# custom paths
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"

###############################################################################
# THEME & PLUGINS 
###############################################################################

# Set name of theme to load.
ZSH_THEME="ehrax"

# Add wisely, as too many plugins slow down shell startup.
plugins=(osx git git-flow-avh docker colored-man-pages)


###############################################################################
# User configuration  
###############################################################################

# uncomment following line if you want red dots to be displayed while waitinf for completion
COMPLETION_WAITING_DOTS="false"

# Disable repeating command before result of command
DISABLE_AUTO_TITLE="true"

# ENABLE_CORRECTION="true"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

export EDITOR='vim'

source $ZSH/oh-my-zsh.sh

###############################################################################
# ALIASES 
###############################################################################
alias so="source ~/.zshrc"
alias home="cd ~/"
alias ls="ls --color"
alias vim="nvim"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

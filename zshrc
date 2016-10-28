export ZSH=/home/alex/.oh-my-zsh
###############################################################################
# CUSTOM THEME {{{ 
###############################################################################

# Set name of the theme to load.
ZSH_THEME="ehrax"

###############################################################################
# }}}
###############################################################################
# PLUGINS {{{  
###############################################################################

# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker colored-man-pages)

###############################################################################
# }}} 
###############################################################################
# User configuration {{{ 
###############################################################################

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="false"
source $ZSH/oh-my-zsh.sh

export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/opt/android-sdk/platform-tools:$PATH 
PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"
# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
# export EDITOR='vim'
# else
# export EDITOR='mvim'
# fi

export EDITOR='nvim'

export DERBY_HOME=/home/alex/App/db-derby-10.12.1.1-bin
export PATH=$DERBY_HOME/bin:$PATH

## fish-like syntax highlighting
# source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# DEFAULT user
DEFAULT_USER="alex"



###############################################################################
# }}}
###############################################################################
# ALIASES {{{
###############################################################################
alias yi="yaourt"
alias so="source ~/.zshrc"
alias home="cd ~/"
alias int="~/App/idea/bin/idea.sh"
alias vim="nvim"
alias dot="cd ~/Dotfiles"
alias pycharm="~/App/pycharm/bin/pycharm.sh"
alias src="cd ~/Src"
alias and='~/App/android-studio/bin/studio.sh'

# Start & Stop Eduroam
alias edu="sudo netctl start eduroam"

# Start & Stop network
alias nt="sudo netctl start"
alias ntd="sudo netctl stop"

alias tmux='env TERM=xterm-256color tmux'



###############################################################################
# }}}
###############################################################################
# FUNCTIONS {{{
###############################################################################
# ls after every cd 
function chpwd() 
{
    emulate -L zsh
    ls
}

auto-ls () 
{
    if [[ $#BUFFER -eq 0 ]]; then
        echo ""
        ls
        echo -e "\n"
    else
        zle .$WIDGET
    fi
}

zle -N accept-line auto-ls
zle -N other-widget auto-ls

###############################################################################
# }}}

# fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

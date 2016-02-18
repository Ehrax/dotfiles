export ZSH=/home/alex/.oh-my-zsh
###############################################################################
# {{{ CUSTOM THEME 
# 
# Set name of the theme to load.
###############################################################################

# ZSH_THEME="agnoster"
# ZSH_THEME="bullet-train"
ZSH_THEME="alanpeabody"

###############################################################################
# }}}

###############################################################################
# {{{ PLUGINS 
# 
# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker colored-man-pages tmux)

# fuzzy-finder
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

###############################################################################
# }}} 

###############################################################################
# {{{ User configuration
###############################################################################

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="false"
source $ZSH/oh-my-zsh.sh

export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/opt/android-sdk/platform-tools:$PATH # export VISUAL="vim"

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
# export EDITOR='vim'
# else
# export EDITOR='mvim'
# fi

export EDITOR='vim'

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/base16-ocean.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL
eval $(dircolors ~/.dircolors)

## fish-like syntax highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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
alias int="~/Applications/idea-IU-143.1184.17/bin/idea.sh"
alias sopra="cd /home/alex/Studium/Sopra/git/"
alias meinserver="ssh root@87.106.15.110"

# Start & Stop Eduroam
alias edu="sudo netctl start eduroam"
alias dedu="sudo netctl stop eduroam"

# Start & Stop network
alias nt="sudo netctl start"
alias dnt="sudo netclt stop"

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

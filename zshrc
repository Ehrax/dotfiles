###############################################################################
# PATH
###############################################################################

# Path to your oh-my-zsh installation.
export ZSH=/Users/alexanderrasputin/.oh-my-zsh
# RVM
export PATH="$PATH:$HOME/.rvm/bin"
# BREW
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"

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
echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.bash_profile
source ~/.bash_profile

###############################################################################
# ALIASES
###############################################################################
alias so="source ~/.zshrc"
alias home="cd ~/"
alias vim="nvim"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# =============================================================================
# Fish Shell Configuration
# =============================================================================

# Suppress fish greeting
set -g fish_greeting

# =============================================================================
# PATH Configuration
# =============================================================================

# Homebrew (Apple Silicon vs Intel)
if test -d /opt/homebrew
    set -gx HOMEBREW_PREFIX /opt/homebrew
else
    set -gx HOMEBREW_PREFIX /usr/local
end
fish_add_path $HOMEBREW_PREFIX/bin

# Flutter / FVM
set -gx FVM_HOME $HOME/.fvm
fish_add_path $FVM_HOME/default/bin
fish_add_path $HOME/.pub-cache/bin

# Android SDK (via Android Studio)
set -gx ANDROID_HOME $HOME/Library/Android/sdk
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/platform-tools

# Rust / Cargo
fish_add_path $HOME/.cargo/bin

# Bun
set -gx BUN_INSTALL $HOME/.bun
fish_add_path $BUN_INSTALL/bin

# =============================================================================
# Tool Initialization
# =============================================================================

# Starship prompt
if type -q starship
    starship init fish | source
end

# Zoxide (smart cd)
if type -q zoxide
    zoxide init fish | source
end

# fnm (Fast Node Manager)
if type -q fnm
    fnm env --use-on-cd --shell fish | source
end

# rbenv (Ruby Version Manager)
if type -q rbenv
    status --is-interactive; and rbenv init - fish | source
end

# fzf key bindings
if type -q fzf
    fzf --fish | source
end

# =============================================================================
# Environment Variables
# =============================================================================

# Editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# fzf configuration (use fd for faster search)
if type -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type file --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type directory --hidden --follow --exclude .git'
end

# =============================================================================
# Aliases - Modern CLI Replacements
# =============================================================================

# bat (better cat)
if type -q bat
    alias cat='bat --paging=never'
    alias catp='bat'  # with pager
end

# eza (better ls)
if type -q eza
    alias ls='eza --icons'
    alias ll='eza -la --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --icons --level=2'
    alias tree='eza --tree --icons'
end

# fd (better find)
if type -q fd
    alias find='fd'
end

# ripgrep (better grep)
if type -q rg
    alias grep='rg'
end

# btop (better top)
if type -q btop
    alias top='btop'
end

# =============================================================================
# Git Aliases
# =============================================================================

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias lg='lazygit'

# =============================================================================
# Utility Aliases
# =============================================================================

alias vim='nvim'
alias v='nvim'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Quick directory navigation
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias p='cd ~/Projects'

# Reload fish config
alias reload='source ~/.config/fish/config.fish'

# =============================================================================
# Functions
# =============================================================================

# Create directory and cd into it
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Quick notes
function note
    if test (count $argv) -eq 0
        nvim ~/notes.md
    else
        echo $argv >> ~/notes.md
    end
end

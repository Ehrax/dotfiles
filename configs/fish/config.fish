# =============================================================================
# Fish Shell Configuration
# =============================================================================

# Suppress fish greeting
set -g fish_greeting

# =============================================================================
# Cursor Configuration (for Ghostty / terminals)
# =============================================================================

# Force Fish to set cursor styles (needed for Ghostty)
set -g fish_vi_force_cursor 1

# Set all cursor modes to non-blinking block
# Values: block, line, underscore (prepend "blinking-" for blinking variants)
set -g fish_cursor_default block
set -g fish_cursor_insert block
set -g fish_cursor_replace_one block
set -g fish_cursor_replace block
set -g fish_cursor_visual block
set -g fish_cursor_external block
set -g fish_cursor_unknown block

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

# Java (Android Studio bundled JDK — required for Gradle / React Native)
set -l android_jbr /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
if test -d $android_jbr
    set -gx JAVA_HOME $android_jbr
    fish_add_path $JAVA_HOME/bin
end

# Rust / Cargo
fish_add_path $HOME/.cargo/bin

# Bun
set -gx BUN_INSTALL $HOME/.bun
fish_add_path $BUN_INSTALL/bin

# Load last set Claude config dir
if test -f ~/.fish_claude_dir
    source ~/.fish_claude_dir
end

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
alias cl='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Quick directory navigation
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias p='cd ~/Projects'

# Reload fish config
alias reload='source ~/.config/fish/config.fish'

# Disk cleanup
set -l _dotfiles_dir (path dirname (path dirname (path dirname (realpath (status filename)))))
alias sweep="bash $_dotfiles_dir/scripts/sweep.sh"

# =============================================================================
# Tmux
# =============================================================================

alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tks='tmux kill-server'

# =============================================================================
# Claude Code
# =============================================================================

alias c="clear; claude --dangerously-skip-permissions --model opus"
function cw --description "Claude Code in a worktree"
    clear
    if test (count $argv) -gt 0
        claude --dangerously-skip-permissions --model opus --worktree=$argv[1] --tmux
    else
        claude --dangerously-skip-permissions --model opus --worktree --tmux
    end
end
alias cwl="git worktree list"
function cwd --description "Remove a git worktree"
    if test (count $argv) -eq 0
        echo "Usage: cwd <worktree-path>"
        echo "Run cwl to list worktrees"
        return 1
    end
    git worktree remove $argv[1] && git worktree prune
end

# Claude config dir switchers
function cc --description "Switch to personal Claude config"
    echo "set -gx CLAUDE_CONFIG_DIR \"$HOME/.claude\"" > ~/.fish_claude_dir
    set -gx CLAUDE_CONFIG_DIR "$HOME/.claude"
    echo "Switched to personal ($HOME/.claude)"
end

function cm --description "Switch to work Claude config"
    echo "set -gx CLAUDE_CONFIG_DIR \"$HOME/.claude-work\"" > ~/.fish_claude_dir
    set -gx CLAUDE_CONFIG_DIR "$HOME/.claude-work"
    echo "Switched to work ($HOME/.claude-work)"
end


# =============================================================================
# Git Worktree Functions (for parallel development)
# =============================================================================

# Helper: resolve main worktree root path
function __wt_main_root
    set -l lines (git worktree list --porcelain 2>/dev/null)
    if test (count $lines) -eq 0
        return 1
    end
    string replace 'worktree ' '' -- $lines[1]
end

# Create a new worktree as a sibling directory with a new branch
# Usage: wt feature-name [base-branch]
function wt --description "Create git worktree as sibling dir"
    if test (count $argv) -eq 0
        echo "Usage: wt <branch-name> [base-branch]"
        return 1
    end

    set -l branch_name $argv[1]
    set -l base_branch main
    if test (count $argv) -ge 2
        set base_branch $argv[2]
    end

    set -l main_root (__wt_main_root)
    if test -z "$main_root"
        echo "Error: not inside a git repository"
        return 1
    end

    set -l project_name (basename $main_root)
    set -l parent_dir (dirname $main_root)
    set -l dir_suffix (string replace -a '/' '-' $branch_name)
    set -l worktree_path $parent_dir/$project_name-$dir_suffix

    if test -d $worktree_path
        echo "Error: directory already exists: $worktree_path"
        return 1
    end

    echo "Creating worktree at $worktree_path (branch: $branch_name from $base_branch)"
    git worktree add -b $branch_name $worktree_path $base_branch
    and echo "Done. cd with: wtc $branch_name"
end

# List all worktrees
function wtl --description "List git worktrees"
    git worktree list
end

# Remove a worktree by branch name
# Usage: wtr feature-name
function wtr --description "Remove git worktree by branch name"
    if test (count $argv) -eq 0
        echo "Usage: wtr <branch-name>"
        return 1
    end

    set -l branch_name $argv[1]
    set -l main_root (__wt_main_root)
    if test -z "$main_root"
        echo "Error: not inside a git repository"
        return 1
    end

    set -l project_name (basename $main_root)
    set -l parent_dir (dirname $main_root)
    set -l dir_suffix (string replace -a '/' '-' $branch_name)
    set -l worktree_path $parent_dir/$project_name-$dir_suffix

    if not test -d $worktree_path
        echo "Error: worktree directory not found: $worktree_path"
        return 1
    end

    # If we are inside the worktree being removed, cd out first
    if string match -q "$worktree_path*" (pwd)
        echo "Currently inside this worktree, switching to $main_root"
        cd $main_root
    end

    echo "Removing worktree: $worktree_path"
    git worktree remove $worktree_path
    and git worktree prune
    and echo "Worktree removed and pruned."
end

# CD into a worktree by branch name
# Usage: wtc feature-name
function wtc --description "CD into git worktree by branch name"
    if test (count $argv) -eq 0
        echo "Usage: wtc <branch-name>"
        return 1
    end

    set -l branch_name $argv[1]
    set -l main_root (__wt_main_root)
    if test -z "$main_root"
        echo "Error: not inside a git repository"
        return 1
    end

    set -l project_name (basename $main_root)
    set -l parent_dir (dirname $main_root)
    set -l dir_suffix (string replace -a '/' '-' $branch_name)
    set -l worktree_path $parent_dir/$project_name-$dir_suffix

    if not test -d $worktree_path
        echo "Error: worktree directory not found: $worktree_path"
        return 1
    end

    cd $worktree_path
end

# Create worktree and launch Claude Code in it
# Usage: wtcc feature-name [base-branch]
function wtcc --description "Create worktree and start Claude Code"
    if test (count $argv) -eq 0
        echo "Usage: wtcc <branch-name> [base-branch]"
        return 1
    end

    wt $argv
    and wtc $argv[1]
    and echo "Starting Claude Code in worktree..."
    and claude --dangerously-skip-permissions
end

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
set -gx PATH $HOME/.local/bin $PATH

# opencode
fish_add_path /Users/ehrax/.opencode/bin

# thanks to ys.reflect() for his awesome oh-my-zsh theme!

# Directory info.
local current_dir='${PWD/#$HOME/~}'
local return_code='%(?..%{$fg[red]%}%? ↵%{$reset_color%})'

# Git info.
local git_info='$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[white]%} on git:%{$reset_color%}%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✓"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} ✚"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%} ✹"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✖"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%} ➜"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%} ═"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%} ✭"

if [[ $USER == "root" ]]; then
  CARETCOLOR="red"
else
  CARETCOLOR="white"
fi

# Prompt format:
PROMPT="
%{$terminfo[bold]$fg[red]%}┌%{$reset_color%} \
%{$fg[blue]%}[%{$reset_color%}%T%{$fg[blue]%}]%{$reset_color%} \
%{$terminfo[bold]$fg[yellow]%}${current_dir}%{$reset_color%}\
${git_info}
%{$terminfo[bold]$fg[red]%}└❱ %{$reset_color%}"

RPROMPT="${return_code}$(git_prompt_status)%{$reset_color%}"

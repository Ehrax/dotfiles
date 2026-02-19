# Tmux Setup

Terminal multiplexer for session management, pane splitting, and seamless
navigation with Neovim.

## Quick Start

```bash
# Start tmux
t

# Create a named session
tn work

# List sessions
tl

# Attach to a session
ta work
```

## Key Bindings

### Prefix

The prefix key is **Ctrl+Space** (instead of the default Ctrl+b).

### Navigation (no prefix needed)

| Key | Action |
|-----|--------|
| `Ctrl+h` | Move left (works across vim splits and tmux panes) |
| `Ctrl+j` | Move down (works across vim splits and tmux panes) |
| `Ctrl+k` | Move up (works across vim splits and tmux panes) |
| `Ctrl+l` | Move right (works across vim splits and tmux panes) |

### Pane Management

| Key | Action |
|-----|--------|
| `prefix + \|` | Split pane horizontally |
| `prefix + -` | Split pane vertically |
| `prefix + x` | Kill pane |

### Window Management

| Key | Action |
|-----|--------|
| `prefix + c` | New window |
| `prefix + n` | Next window |
| `prefix + p` | Previous window |
| `prefix + 1-9` | Switch to window by number |

### Session Management

| Key | Action |
|-----|--------|
| `prefix + s` | Session picker |
| `prefix + d` | Detach from session |
| `prefix + r` | Reload config |

### Copy Mode (vi keys)

| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Copy to system clipboard |
| `q` | Exit copy mode |

## Fish Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `t` | `tmux` | Start tmux |
| `ta` | `tmux attach -t` | Attach to session |
| `tn` | `tmux new -s` | New named session |
| `tl` | `tmux ls` | List sessions |
| `tk` | `tmux kill-session -t` | Kill session |
| `tks` | `tmux kill-server` | Kill tmux server |

## Session Persistence

Sessions are automatically saved every 15 minutes by `tmux-continuum` and
restored on tmux start via `tmux-resurrect`. Neovim sessions can also be restored if a compatible session plugin
(e.g. `persistence.nvim`) is installed.

## Plugin Management

Plugins are managed by TPM (Tmux Plugin Manager):

| Key | Action |
|-----|--------|
| `prefix + I` | Install plugins (TPM default, not defined in this config) |
| `prefix + U` | Update plugins (TPM default, not defined in this config) |

## How Vim-Tmux Navigation Works

The `vim-tmux-navigator` plugin creates seamless pane switching:

1. When you press `Ctrl+h` in tmux, it checks if the active pane is running vim/nvim
2. If vim is running, it sends the key to vim (which moves between vim splits)
3. If vim is NOT running, tmux moves to the adjacent pane

This means `Ctrl+h/j/k/l` works transparently whether you are moving between
vim splits, tmux panes, or crossing from a vim split into a tmux pane.

> **Note:** The tmux-side keybindings for navigation are configured directly in
> `tmux.conf` (not installed via TPM). The Neovim side uses the
> `vim-tmux-navigator` plugin, managed by lazy.nvim.

## Troubleshooting

### Colors look wrong
Ensure Ghostty reports `xterm-256color` (already configured). The tmux config
uses `tmux-256color` with RGB overrides.

### Navigation not working between vim and tmux
1. Verify the Neovim plugin is installed: `:Lazy` and check for `vim-tmux-navigator`
2. Verify tmux keybindings: `tmux list-keys | grep C-h`

### Slow escape key in vim
The `escape-time` is set to 0 in the config. If you still experience delay,
check that no other config is overriding this value.

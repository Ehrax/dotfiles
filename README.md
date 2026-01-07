# Dotfiles

Personal macOS development environment configuration.

## Quick Start

```bash
git clone https://github.com/Ehrax/dotfiles ~/Projects/Dotfiles
cd ~/Projects/Dotfiles
./init.sh
```

The setup script is interactive and will guide you through:
1. Installing Homebrew packages
2. Creating symlinks
3. Setting up Fish shell
4. Optional: Flutter, Ruby, Node.js environments
5. Optional: macOS system preferences

## What's Included

### Shell & Terminal
- **Fish** - Modern shell with great defaults
- **Starship** - Minimal, fast prompt
- **Ghostty** - GPU-accelerated terminal (One Dark theme)

### Editor
- **Neovim** + LazyVim - Modern Vim with LSP, treesitter, etc.
- One Dark colorscheme
- Animations/indent guides disabled

### CLI Tools
| Tool | Replaces | Description |
|------|----------|-------------|
| `bat` | cat | Syntax highlighting |
| `eza` | ls | Icons, git integration |
| `fd` | find | Faster, simpler syntax |
| `ripgrep` | grep | Blazing fast search |
| `zoxide` | cd | Smart directory jumping |
| `delta` | diff | Beautiful git diffs |
| `btop` | top | Resource monitor |
| `lazygit` | - | Terminal UI for git |

### Development
- **fnm** - Fast Node Manager
- **bun** - JavaScript runtime
- **rbenv** - Ruby version manager
- **fvm** - Flutter version manager
- **Claude Code** - AI coding assistant

## Directory Structure

```
Dotfiles/
├── configs/
│   ├── fish/           # Fish shell config
│   ├── nvim/           # LazyVim configuration
│   ├── git/            # Git config + global ignore
│   ├── starship/       # Starship prompt
│   ├── ghostty/        # Terminal config
│   └── lazygit/        # Lazygit config
├── scripts/
│   └── macos.sh        # macOS system preferences
├── docs/
│   ├── FLUTTER_SETUP.md
│   └── MACOS_SETUP.md
├── archive/            # Old configs (zsh, etc.)
├── Brewfile            # Homebrew packages
└── init.sh             # Setup script
```

## Key Bindings

### Fish Shell
- Modern tool aliases: `cat`→bat, `ls`→eza, `find`→fd, etc.
- `lg` - Open Lazygit
- `v` / `vim` - Open Neovim
- `reload` - Reload fish config

### Neovim (LazyVim)
- `<Space>` - Leader key
- `<Left>` / `<Right>` - Buffer navigation
- `<BS>` - Clear search highlight
- `<Esc><Esc>` - Save file

## Manual Steps

After running `init.sh`:

1. **Restart terminal** or run `exec fish`
2. **Open Neovim** - plugins will auto-install
3. **Logout/restart** - for keyboard repeat settings

For Flutter development, see [docs/FLUTTER_SETUP.md](docs/FLUTTER_SETUP.md)

## Customization

Configs are symlinked to `~/.config/`. Edit files in this repo and changes apply immediately.

To add Homebrew packages, edit `Brewfile` and run:
```bash
brew bundle
```

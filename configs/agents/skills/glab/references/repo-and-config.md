# Repository, Auth & Configuration — glab repo / glab auth / glab config

Complete reference for repository management, authentication, and glab configuration.

## Repository — glab repo

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `repo clone` | Clone a repository |
| `repo create` | Create a new repository |
| `repo fork` | Fork a repository |
| `repo list` | List repositories |
| `repo view` | View repository details |
| `repo search` | Search repositories |
| `repo archive` | Download repository archive |
| `repo delete` | Delete a repository |
| `repo transfer` | Transfer to another namespace |
| `repo mirror` | Configure repository mirroring |
| `repo members` | Manage repository members |
| `repo contributors` | View contributors |
| `repo publish` | Make a repository public |
| `repo update` | Modify repository settings |

### glab repo clone

```bash
# Clone by path
glab repo clone owner/repo

# Clone into specific directory
glab repo clone owner/repo ./my-dir

# Clone by project ID
glab repo clone 12345

# Clone a specific branch
glab repo clone owner/repo -- --branch develop

# Clone all repositories in a group
glab repo clone -g my-group

# Clone all repos in group (with pagination)
glab repo clone -g my-group --per-page 100 --page 1

# Clone preserves fork relationships — adds upstream remote automatically
```

### glab repo create

```bash
# Interactive creation
glab repo create

# Create with name (uses current directory name if omitted)
glab repo create my-new-project

# Create with options
glab repo create my-project --description "My project" --visibility private

# Create in a group
glab repo create -g my-group my-project
```

### glab repo fork

```bash
# Fork the current repo
glab repo fork

# Fork and clone
glab repo fork --clone

# Fork with custom name/path
glab repo fork --name my-fork --path my-fork-path

# Fork a specific repo
glab repo fork owner/repo
```

### glab repo list

```bash
# List your repos
glab repo list

# List repos in a group
glab repo list -g my-group

# Exclude archived repos
glab repo list --archived=false

# JSON output
glab repo list -F json --per-page 100
```

### glab repo view / search / archive

```bash
# View repo details
glab repo view owner/repo
glab repo view --web                # Open in browser

# Search repos
glab repo search -s "keyword"

# Download archive
glab repo archive owner/repo
glab repo archive owner/repo --format zip
```

### glab repo delete / transfer

```bash
# Delete repository (destructive!)
glab repo delete owner/repo --yes

# Transfer to another namespace
glab repo transfer owner/repo --target-namespace new-group
```

## Authentication — glab auth

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `auth login` | Authenticate to a GitLab instance |
| `auth logout` | Remove authentication for a host |
| `auth status` | Display authentication status |
| `auth token` | Display or set the auth token |

### glab auth login

Interactive and non-interactive authentication.

**Minimum required token scopes:** `api`, `write_repository`

```bash
# Interactive login (prompts for host, token, protocol)
glab auth login

# Non-interactive with token
glab auth login --hostname gitlab.example.com --token glpat-XXXXXXXXXXXXXXXXXXXX

# Specify protocols
glab auth login --hostname gitlab.example.com --git-protocol ssh --api-protocol https

# Login via stdin (for CI)
echo "glpat-XXXXXXXXXXXXXXXXXXXX" | glab auth login --hostname gitlab.example.com --stdin
```

### glab auth status

```bash
glab auth status
# Displays: hostname, git protocol, API protocol, API endpoint, GraphQL endpoint, token status
```

### glab auth logout

```bash
glab auth logout                     # Logout from default host
glab auth logout --hostname gitlab.example.com
```

## Configuration — glab config

Configuration stored in `~/.config/glab-cli/config.yml`.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `config set` | Set a configuration value |
| `config get` | Get a configuration value |
| `config list` | List all configuration |

### Examples

```bash
# Set git protocol for a host
glab config set -h gitlab.example.com git_protocol ssh

# Set API protocol
glab config set -h gitlab.example.com api_protocol https

# Set default editor
glab config set editor vim

# Set default browser
glab config set browser firefox

# Get a config value
glab config get git_protocol

# List all config
glab config list
```

### Configuration Keys

| Key | Description | Values |
|-----|-------------|--------|
| `git_protocol` | Protocol for git operations | `ssh`, `https` |
| `api_protocol` | Protocol for API calls | `http`, `https` |
| `editor` | Text editor for descriptions | Any editor command |
| `browser` | Web browser | Any browser command |
| `glamour_style` | Markdown rendering style | `dark`, `light`, `notty` |

## Key Management

### SSH Keys — glab ssh-key

```bash
glab ssh-key list                    # List SSH keys
glab ssh-key add ~/.ssh/id_ed25519.pub --title "My Laptop"
glab ssh-key delete 12345
```

### GPG Keys — glab gpg-key

```bash
glab gpg-key list                    # List GPG keys
glab gpg-key add ./my-key.gpg
glab gpg-key delete 12345
```

### Deploy Keys — glab deploy-key

```bash
glab deploy-key list                 # List deploy keys
glab deploy-key add ~/.ssh/deploy.pub --title "CI Server" --can-push
glab deploy-key delete 12345
```

## Shell Completion — glab completion

Generate shell completion scripts.

```bash
# Bash
glab completion -s bash > /etc/bash_completion.d/glab

# Zsh
glab completion -s zsh > "${fpath[1]}/_glab"

# Fish
glab completion -s fish > ~/.config/fish/completions/glab.fish

# PowerShell
glab completion -s powershell | Out-File ~\glab.ps1
```

## Tokens — glab token

Manage personal access tokens.

```bash
glab token list                      # List your tokens
glab token create --name "CI Token" --scopes api,read_repository --expires-at 2025-12-31
glab token revoke 12345
```

## Users — glab user

```bash
glab user events                     # View your recent activity
```

## Common Patterns for Agents

### Initial Setup

```bash
# 1. Login
glab auth login

# 2. Verify
glab auth status

# 3. Clone project
glab repo clone my-group/my-project

# 4. Set up shell completion (optional)
glab completion -s zsh > "${fpath[1]}/_glab"
```

### Multi-Instance Setup

```bash
# Login to multiple GitLab instances
glab auth login --hostname gitlab.com
glab auth login --hostname gitlab.example.com

# glab auto-detects which host to use based on git remotes
```

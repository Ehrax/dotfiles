# Issues & Incidents — glab issue / glab incident

Complete reference for managing GitLab issues and incidents from the CLI.

## Issue Subcommands

| Subcommand | Alias | Description |
|------------|-------|-------------|
| `issue create` | `issue new` | Create a new issue |
| `issue list` | `issue ls` | List issues |
| `issue view` | — | Display issue details |
| `issue update` | — | Update issue attributes |
| `issue close` | — | Close an issue |
| `issue reopen` | — | Reopen a closed issue |
| `issue delete` | `issue del` | Delete an issue |
| `issue note` | `issue comment` | Add a comment |
| `issue subscribe` | `issue sub` | Subscribe to notifications |
| `issue unsubscribe` | `issue unsub` | Unsubscribe from notifications |
| `issue todo` | — | Add to your to-do list |
| `issue board` | — | View and interact with issue boards |

## glab issue create

Create a new issue.

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--title` | `-t` | string | Issue title |
| `--description` | `-d` | string | Issue description (use `-` to open editor) |
| `--assignee` | `-a` | strings | Assign to users by username (comma-separated or repeated) |
| `--label` | `-l` | strings | Add labels (comma-separated or repeated) |
| `--milestone` | `-m` | string | Milestone ID or title |
| `--confidential` | `-c` | bool | Mark as confidential |
| `--weight` | `-w` | int | Issue weight (>= 0) |
| `--due-date` | — | string | Due date in `YYYY-MM-DD` format |
| `--epic` | — | int | Epic ID to add the issue to |
| `--linked-issues` | — | ints | IIDs of issues to link (comma-separated or repeated) |
| `--linked-mr` | — | int | MR IID to resolve all issues in |
| `--link-type` | — | string | Link type: `relates_to` (default), `blocks`, `is_blocked_by` |
| `--time-estimate` | `-e` | string | Time estimate (e.g., `1h30m`, `2d`) |
| `--time-spent` | `-s` | string | Time already spent |
| `--no-editor` | — | bool | Use prompt instead of editor |
| `--web` | — | bool | Continue creation in web browser |
| `--yes` | `-y` | bool | Skip confirmation prompts |
| `--recover` | — | bool | Save/restore options on failure (experimental) |

### Examples

```bash
# Interactive creation
glab issue create

# Quick issue with title, label, and milestone
glab issue create -t "Fix login timeout" -l bug -m v2.1

# Confidential security issue linked to an MR
glab issue new -t "Fix CVE-YYYY-XXXX" -l security --linked-mr 123 -c

# Issue with due date and weight
glab issue create -t "Write docs" --due-date 2025-03-15 -w 3

# Issue linked to other issues
glab issue create -t "Parent task" --linked-issues 10,11,12 --link-type blocks

# Open in browser to finish
glab issue create -t "Complex issue" --web
```

## glab issue list

List project issues with filtering.

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--assignee` | `-a` | string | Filter by assignee username |
| `--author` | `-A` | string | Filter by author username |
| `--label` | `-l` | strings | Filter by labels |
| `--milestone` | `-m` | string | Filter by milestone |
| `--mine` | — | bool | Show only your issues |
| `--confidential` | — | bool | Filter by confidential status |
| `--closed` | `-c` | bool | Show only closed issues |
| `--all` | — | bool | Show all issues (all states) |
| `--group` | `-g` | string | List issues for a group |
| `--search` | `-s` | string | Search in title and description |
| `--in` | — | string | Search scope: `title`, `description`, or `title,description` |
| `--order` | `-o` | string | Order by: `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` |
| `--sort` | — | string | Sort: `asc` or `desc` |
| `--per-page` | `-P` | int | Items per page (default 30) |
| `--page` | `-p` | int | Page number |
| `--output` | `-F` | string | Output format: `text` or `json` |

### Examples

```bash
# All open issues (default)
glab issue list

# Issues assigned to you
glab issue list --mine

# Closed bugs for milestone v3.1
glab issue list -c -l bug -m v3.1

# Search issues
glab issue list -s "timeout" --in title

# JSON output for scripting
glab issue list -F json --per-page 100

# Group-level issues
glab issue list -g my-group --label "P1"
```

## glab issue view

Display issue details.

```bash
glab issue view 123                 # View issue #123
glab issue view 123 --web           # Open in browser
glab issue view 123 --comments      # Include comments
glab issue view 123 --system-logs   # Include system activity
```

## glab issue update

Update issue attributes.

```bash
glab issue update 123 --title "New title"
glab issue update 123 --label "reviewed" --unlabel "triage"
glab issue update 123 --milestone "v2.0"
glab issue update 123 --assignee user1,user2
glab issue update 123 --due-date "2025-06-01"
glab issue update 123 --weight 5
glab issue update 123 --confidential    # Make confidential
glab issue update 123 --milestone ""    # Unassign milestone (use "" or 0)
```

## glab issue close / reopen / delete

```bash
glab issue close 123               # Close issue
glab issue reopen 123              # Reopen issue
glab issue delete 123              # Delete permanently
glab issue delete 123 124 125      # Delete multiple
```

## glab issue note

Add a comment to an issue.

```bash
glab issue note 123 -m "Investigated — this is caused by the timeout config"
glab issue note 123                # Opens editor for longer comment
```

## glab issue subscribe / unsubscribe / todo

```bash
glab issue subscribe 123           # Subscribe to notifications
glab issue sub 123                 # Alias
glab issue unsubscribe 123         # Unsubscribe
glab issue todo 123                # Add to your to-do list
```

## glab issue board

View and interact with issue boards.

```bash
glab issue board view                          # View default board
glab issue board view --assignee username      # Filter by assignee
glab issue board view --labels "bug,P1"        # Filter by labels
glab issue board view --milestone "v2.0"       # Filter by milestone
```

## Incidents — glab incident

Incidents share many commands with issues but are focused on operational incidents.

| Subcommand | Description |
|------------|-------------|
| `incident list` | List incidents |
| `incident view` | View incident details |
| `incident close` | Close an incident |
| `incident reopen` | Reopen an incident |
| `incident note` | Add a comment |
| `incident subscribe` | Subscribe to notifications |
| `incident unsubscribe` | Unsubscribe |
| `incident todo` | Add to to-do list |

### Examples

```bash
glab incident list                    # List open incidents
glab incident view 456                # View incident details
glab incident view 456 --web         # Open in browser
glab incident view 456 --comments    # Include comments
glab incident close 456              # Close incident
glab incident note 456 -m "Root cause identified"
```

## Common Patterns for Agents

### Triage Workflow

```bash
# List unassigned, high-priority issues
glab issue list --label "P1" --assignee "" -F json

# Assign and label
glab issue update 123 --assignee developer1 --label "in-progress" --unlabel "triage"

# Add a comment
glab issue note 123 -m "Assigned to @developer1 for sprint 5"
```

### Create Issue and Linked MR

```bash
# Create the issue
glab issue create -t "Implement feature X" -l enhancement -m v2.0

# Later, create an MR that closes it
glab mr create --related-issue 123 --copy-issue-labels --fill
```

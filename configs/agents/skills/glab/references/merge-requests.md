# Merge Requests — glab mr

Complete reference for managing GitLab merge requests from the CLI.

## Subcommands

| Subcommand | Alias | Description |
|------------|-------|-------------|
| `mr create` | `mr new` | Create a new merge request |
| `mr list` | `mr ls` | List merge requests |
| `mr view` | — | Display merge request details |
| `mr checkout` | — | Check out MR branch locally |
| `mr diff` | — | View MR diff |
| `mr merge` | — | Merge a merge request |
| `mr approve` | — | Approve a merge request |
| `mr revoke` | — | Revoke approval |
| `mr approvers` | — | List MR approvers |
| `mr note` | `mr comment` | Add a comment to a MR |
| `mr close` | — | Close a merge request |
| `mr reopen` | — | Reopen a closed merge request |
| `mr update` | — | Update MR attributes |
| `mr delete` | `mr del` | Delete a merge request |
| `mr rebase` | — | Rebase the MR source branch |
| `mr todo` | — | Add MR to your to-do list |
| `mr subscribe` | `mr sub` | Subscribe to MR notifications |
| `mr unsubscribe` | `mr unsub` | Unsubscribe from MR notifications |
| `mr issues` | — | List issues that will close when MR is merged |

## glab mr create

Create a new merge request from the current or specified branch.

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--title` | `-t` | string | MR title |
| `--description` | `-d` | string | MR description (use `-` to open editor) |
| `--target-branch` | `-b` | string | Target branch to merge into |
| `--source-branch` | `-s` | string | Source branch (default: current branch) |
| `--assignee` | `-a` | strings | Assign to users by username (comma-separated or repeated) |
| `--reviewer` | — | strings | Request review from users by username |
| `--label` | `-l` | strings | Add labels (comma-separated or repeated) |
| `--milestone` | `-m` | string | Milestone ID or title |
| `--draft` | — | bool | Mark as draft |
| `--wip` | — | bool | Mark as draft (alias for `--draft`) |
| `--fill` | `-f` | bool | Auto-fill title/description from commit messages |
| `--fill-commit-body` | — | bool | Fill description with each commit body |
| `--yes` | `-y` | bool | Skip confirmation prompts |
| `--push` | — | bool | Push commits before creating MR |
| `--squash-before-merge` | — | bool | Squash commits on merge |
| `--remove-source-branch` | — | bool | Delete source branch on merge |
| `--allow-collaboration` | — | bool | Allow commits from other members |
| `--related-issue` | `-i` | string | Create MR for an issue (uses issue title if `--title` omitted) |
| `--copy-issue-labels` | — | bool | Copy labels from related issue to MR |
| `--create-source-branch` | — | bool | Create source branch if it doesn't exist |
| `--signoff` | — | bool | Append DCO sign-off to description |
| `--head` | `-H` | string | Select alternate head repository (OWNER/REPO) |
| `--no-editor` | — | bool | Use prompt instead of editor |
| `--web` | `-w` | bool | Continue creation in web browser |
| `--recover` | — | bool | Save/restore options on failure (experimental) |

### Examples

```bash
# Interactive creation
glab mr create

# Quick MR with title and assignee
glab mr create -a username -t "fix annoying bug"

# Draft MR with label, filled from commits
glab mr create -f --draft --label RFC

# Fully automated — no prompts
glab mr create --fill --fill-commit-body --yes

# Open in browser to finish
glab mr create --fill --web

# MR for an issue — copies title, adds closing reference
glab mr create --related-issue 42 --copy-issue-labels

# Push and create in one step
glab mr create --fill --push --yes -b main
```

## glab mr list

List merge requests with filtering.

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--assignee` | `-a` | strings | Filter by assignee username |
| `--author` | `-A` | string | Filter by author username |
| `--reviewer` | — | strings | Filter by reviewer username |
| `--label` | `-l` | strings | Filter by label |
| `--milestone` | `-m` | string | Filter by milestone |
| `--mine` | `-M` | bool | Filter by your MRs (shortcut for `--author=@me`) |
| `--draft` | `-d` | bool | Filter by draft status |
| `--closed` | `-c` | bool | Show only closed MRs |
| `--merged` | — | bool | Show only merged MRs |
| `--all` | — | bool | Show all MRs (all states) |
| `--group` | `-g` | string | List MRs for a group |
| `--order` | `-o` | string | Order by: `created_at`, `updated_at`, `merged_at`, `title`, `priority`, `label_priority`, `milestone_due`, `popularity` |
| `--sort` | `-s` | string | Sort: `asc` or `desc` |
| `--per-page` | `-P` | int | Items per page (default 30) |
| `--page` | `-p` | int | Page number |
| `--output` | `-F` | string | Output format: `text` or `json` |

### Examples

```bash
# All open MRs (default)
glab mr list

# MRs awaiting your review
glab mr list --reviewer=@me

# Your own MRs
glab mr list --mine

# Merged MRs with a specific label
glab mr list --merged --label "feature"

# JSON output for scripting
glab mr list -F json

# MRs for a group
glab mr list -g my-group
```

## glab mr view

Display details of a merge request.

```bash
glab mr view 42                   # View MR #42
glab mr view feature-branch       # View MR by branch name
glab mr view                      # View MR for current branch
glab mr view 42 --web             # Open in browser
glab mr view 42 --comments        # Include comments
glab mr view 42 --system-logs     # Include system activity
```

## glab mr checkout

Check out a merge request's branch locally.

```bash
glab mr checkout 42               # Checkout MR #42 branch
glab mr checkout 42 -b my-branch  # Checkout into a custom local branch name
glab mr checkout 42 -t            # Track the remote branch
```

## glab mr diff

View the diff of a merge request.

```bash
glab mr diff 42                   # View diff
glab mr diff                      # Diff for current branch's MR
glab mr diff 42 --color=never     # No color (for piping)
glab mr diff 42 --raw             # Raw diff format
```

## glab mr merge

Merge a merge request.

```bash
glab mr merge 42                  # Merge (prompts for method)
glab mr merge                     # Merge current branch's MR
glab mr merge 42 --squash         # Squash merge
glab mr merge 42 --rebase         # Rebase merge
glab mr merge 42 --yes            # Skip confirmation
glab mr merge 42 --when-pipeline-succeeds   # Merge when CI passes
```

## glab mr approve / revoke

```bash
glab mr approve 42                # Approve MR #42
glab mr approve                   # Approve current branch's MR
glab mr approve 42 --sha abc123   # Approve only if HEAD matches SHA
glab mr approve 42 43 44          # Approve multiple MRs

glab mr revoke 42                 # Revoke your approval
```

## glab mr note

Add a comment to a merge request.

```bash
glab mr note 42 -m "Looks good, one nit on line 55"
glab mr note -m "LGTM"           # Comment on current branch's MR
```

## glab mr update

Update merge request attributes.

```bash
glab mr update 42 --title "New title"
glab mr update 42 --label "reviewed" --unlabel "needs-review"
glab mr update 42 --milestone "v2.0"
glab mr update 42 --assignee user1,user2
glab mr update 42 --reviewer user3
glab mr update 42 --draft             # Convert to draft
glab mr update 42 --ready             # Mark as ready
```

## glab mr close / reopen / delete

```bash
glab mr close 42                  # Close MR
glab mr reopen 42                 # Reopen closed MR
glab mr delete 42                 # Delete MR permanently
glab mr delete 42 43 44           # Delete multiple
```

## glab mr rebase

```bash
glab mr rebase 42                 # Rebase MR source branch
glab mr rebase                    # Rebase current branch's MR
```

## glab mr subscribe / unsubscribe / todo

```bash
glab mr subscribe 42              # Subscribe to notifications
glab mr unsubscribe 42            # Unsubscribe
glab mr todo 42                   # Add to your to-do list
```

## Common Patterns for Agents

### Full MR Workflow

```bash
# 1. Create MR from current branch
glab mr create --fill --yes -b main --reviewer teamlead --label "ready for review"

# 2. Check CI status
glab ci status

# 3. View MR
glab mr view

# 4. After approval, merge
glab mr merge --squash --yes
```

### Create MR for a Specific Issue

```bash
glab mr create --related-issue 42 --copy-issue-labels --fill --push
```

### Bulk Operations

```bash
# List all open MRs as JSON for processing
glab mr list -F json --per-page 100
```

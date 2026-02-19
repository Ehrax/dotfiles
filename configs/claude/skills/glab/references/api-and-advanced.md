# API, Variables & Advanced — glab api / glab variable / glab snippet / glab stack / glab alias

Complete reference for raw API access, CI/CD variables, snippets, stacked diffs, labels, milestones, and aliases.

## Raw API Access — glab api

Make authenticated HTTP requests to the GitLab REST or GraphQL API.

### Behavior

- **Default method**: GET when no parameters; POST when parameters are provided
- **Auto-detection**: Determines GitLab host from git remotes (falls back to gitlab.com)
- **Placeholders**: `:fullpath`, `:id`, `:repo`, `:namespace`, `:group`, `:user`, `:username`, `:branch` are auto-substituted from current project context

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--field` | `-F` | key=value | Add parameter with type inference (bools, ints, null auto-converted; `@file` reads from file) |
| `--raw-field` | `-f` | key=value | Add parameter as JSON string (no type conversion) |
| `--header` | `-H` | key:value | Add HTTP header |
| `--method` | `-X` | string | HTTP method (GET, POST, PUT, PATCH, DELETE) |
| `--hostname` | — | string | Override GitLab hostname |
| `--input` | — | string | Read request body from file (use `-` for stdin) |
| `--paginate` | — | bool | Fetch all pages of results |
| `--output` | — | string | Output format: `json` (default, pretty-printed) or `ndjson` (newline-delimited) |
| `--include` | `-i` | bool | Include HTTP response headers in output |
| `--silent` | — | bool | Suppress response output |

### REST API Examples

```bash
# Get project members (auto-substitutes :fullpath)
glab api projects/:fullpath/members

# Get specific project's issues
glab api projects/gitlab-com/www-gitlab-com/issues

# Paginate all issues
glab api issues --paginate

# Paginate with ndjson (memory-efficient for large datasets)
glab api issues --paginate --output ndjson

# POST request with fields
glab api projects/:fullpath/issues -F title="New Issue" -F description="Body text"

# PUT request
glab api projects/:fullpath/issues/42 -X PUT -F state_event=close

# DELETE request
glab api projects/:fullpath/pipeline_schedules/15 -X DELETE

# Include response headers
glab api projects/:fullpath/members -i

# Read body from file
glab api projects/:fullpath/issues -X POST --input issue-body.json

# Read body from stdin
echo '{"title":"New Issue"}' | glab api projects/:fullpath/issues -X POST --input -
```

### GraphQL API Examples

```bash
# Simple query
glab api graphql -f query='{ currentUser { username } }'

# Project details
glab api graphql -f query='
  query {
    project(fullPath: "gitlab-org/gitlab-docs") {
      name
      forksCount
      statistics { wikiSize }
      issuesEnabled
      boards { nodes { id name } }
    }
  }
'

# Paginated GraphQL query (uses $endCursor variable)
glab api graphql --paginate -f query='
  query($endCursor: String) {
    project(fullPath: "my-group/my-project") {
      issues(first: 100, after: $endCursor) {
        edges { node { title state } }
        pageInfo { endCursor hasNextPage }
      }
    }
  }
'

# GraphQL with variables
glab api graphql -f query='
  query($path: ID!) {
    project(fullPath: $path) { name description }
  }
' -F path="my-group/my-project"
```

### Field Type Conversion (--field / -F)

| Input | Converted To |
|-------|-------------|
| `"true"` / `"false"` | JSON boolean |
| `"null"` | JSON null |
| Integer strings (`"42"`) | JSON number |
| `@filename` | File contents as string |
| Everything else | JSON string |

Use `--raw-field` / `-f` to force string type (no conversion).

## CI/CD Variables — glab variable

Manage project-level CI/CD variables.

| Subcommand | Description |
|------------|-------------|
| `variable list` | List all CI/CD variables |
| `variable get` | Get a variable's value |
| `variable set` | Create or update a variable |
| `variable update` | Update an existing variable |
| `variable delete` | Delete a variable |
| `variable export` | Export variables |

### Examples

```bash
# List all variables
glab variable list

# Get a specific variable
glab variable get MY_SECRET

# Set a new variable
glab variable set MY_SECRET "s3cret_value"

# Set with options
glab variable set MY_SECRET "value" --masked --protected --scope production

# Update existing variable
glab variable update MY_SECRET "new_value"

# Delete a variable
glab variable delete MY_SECRET

# Export variables (useful for backup)
glab variable export
```

### Variable Flags

| Flag | Description |
|------|-------------|
| `--masked` | Mask the variable in job logs |
| `--protected` | Only expose to protected branches/tags |
| `--scope` | Environment scope (e.g., `production`, `*`) |
| `--type` | Variable type: `env_var` (default) or `file` |
| `--group` | Set variable at group level |

## Snippets — glab snippet

Manage GitLab snippets.

| Subcommand | Description |
|------------|-------------|
| `snippet create` | Create a new snippet |
| `snippet list` | List snippets |
| `snippet view` | View snippet details |
| `snippet delete` | Delete a snippet |

### Examples

```bash
# Create snippet interactively
glab snippet create

# Create from file
glab snippet create -t "My Config" -f config.yml --visibility private

# List snippets
glab snippet list

# View a snippet
glab snippet view 42
```

## Stacked Diffs — glab stack (Experimental)

Create and manage stacked merge requests (stacked diffs). This feature is experimental.

| Subcommand | Description |
|------------|-------------|
| `stack create` | Create a new stack |
| `stack list` | List stacks |
| `stack save` | Save changes with a commit message |
| `stack amend` | Modify the current diff |
| `stack sync` | Push, rebase, and clean up merged branches |
| `stack first` | Navigate to first diff in stack |
| `stack last` | Navigate to last diff in stack |
| `stack next` | Move to next diff |
| `stack prev` | Move to previous diff |
| `stack move` | Move a diff within the stack |
| `stack reorder` | Reorder diffs in the stack |

### Workflow

```bash
# 1. Create a new stack
glab stack create my-feature

# 2. Make changes and save (creates first MR in stack)
# ... edit files ...
glab stack save -m "Part 1: Add data model"

# 3. Continue with next change
# ... edit more files ...
glab stack save -m "Part 2: Add API endpoint"

# 4. Amend the current diff
# ... edit files ...
glab stack amend

# 5. Sync — pushes changes, rebases stack, cleans up merged branches
glab stack sync

# 6. Navigate the stack
glab stack first       # Go to first diff
glab stack next        # Go to next diff
glab stack prev        # Go to previous diff
glab stack last        # Go to last diff

# 7. List all stacks
glab stack list
```

## Labels — glab label

Manage project labels.

| Subcommand | Description |
|------------|-------------|
| `label create` | Create a new label |
| `label list` | List labels |

### Examples

```bash
# List labels
glab label list

# Create a label
glab label create "priority::high" --color "#FF0000" --description "High priority items"
```

## Milestones — glab milestone

Manage project milestones.

| Subcommand | Description |
|------------|-------------|
| `milestone create` | Create a new milestone |
| `milestone list` | List milestones |
| `milestone delete` | Delete a milestone |

### Examples

```bash
# List milestones
glab milestone list

# Create a milestone
glab milestone create --title "v2.0" --description "Major release" --due-date "2025-06-01"

# Delete a milestone
glab milestone delete 5
```

## Aliases — glab alias

Create command shortcuts.

| Subcommand | Description |
|------------|-------------|
| `alias set` | Create or update an alias |
| `alias list` | List all aliases |
| `alias delete` | Delete an alias |

### Examples

```bash
# Create useful aliases
glab alias set mrc 'mr create --fill --yes'
glab alias set mrl 'mr list --reviewer=@me'
glab alias set cis 'ci status --live'
glab alias set myissues 'issue list --mine'

# List aliases
glab alias list

# Delete an alias
glab alias delete mrc

# Use an alias
glab mrc                            # Expands to: glab mr create --fill --yes
```

## Iterations — glab iteration

```bash
glab iteration list                  # List iterations
```

## Secure Files — glab securefile

```bash
glab securefile list                 # List secure files
glab securefile download 42          # Download a secure file
```

## GitLab Duo AI — glab duo

Interact with GitLab Duo AI assistant.

```bash
glab duo ask "How do I set up CI for a Python project?"
```

## Check for Updates

```bash
glab check-update                    # Check if newer glab version is available
```

## Common Patterns for Agents

### Bulk API Operations

```bash
# Get all project members as JSON
glab api projects/:fullpath/members --paginate -F per_page=100

# Close all issues with a specific label
glab issue list -l "wontfix" -F json | jq -r '.[].iid' | while read iid; do
  glab api projects/:fullpath/issues/$iid -X PUT -F state_event=close
done
```

### Export Project Data

```bash
# All issues as ndjson
glab api projects/:fullpath/issues --paginate --output ndjson > issues.ndjson

# All MRs as json
glab mr list -F json --per-page 100 > merge-requests.json

# All variables
glab variable export > variables.env
```

### Productivity Aliases

```bash
glab alias set review 'mr list --reviewer=@me'
glab alias set todo 'mr list --assignee=@me --draft=false'
glab alias set quick-mr 'mr create --fill --fill-commit-body --yes --push'
```

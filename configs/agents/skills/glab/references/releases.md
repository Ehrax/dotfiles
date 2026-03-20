# Releases — glab release

Complete reference for managing GitLab releases from the CLI.

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `release create` | Create a new release (or update an existing one) |
| `release list` | List releases |
| `release view` | View release details |
| `release delete` | Delete a release |
| `release download` | Download release assets |
| `release upload` | Upload assets to an existing release |

## glab release create

Create a new release or update an existing one. Requires at least Developer role.

### Syntax

```bash
glab release create <tag> [<files>...] [flags]
```

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--name` | `-n` | string | Release title/name |
| `--notes` | `-N` | string | Release notes (supports Markdown) |
| `--notes-file` | `-F` | string | Read notes from file (use `-` for stdin) |
| `--milestone` | `-m` | strings | Associated milestones (comma-separated or repeated) |
| `--ref` | `-r` | string | Commit SHA, tag, or branch to release from (if tag doesn't exist) |
| `--released-at` | `-D` | string | Release date in ISO 8601 format |
| `--tag-message` | `-T` | string | Message for a new annotated tag |
| `--assets-links` | `-a` | string | JSON representation of asset links |
| `--use-package-registry` | — | bool | Upload assets to generic package registry |
| `--no-close-milestone` | — | bool | Don't close milestones after creating release |
| `--no-update` | — | bool | Don't update if release already exists |
| `--publish-to-catalog` | — | bool | Publish to CI/CD catalog (experimental) |

### Examples

```bash
# Interactive creation
glab release create v1.0.1

# With inline notes
glab release create v1.0.1 --notes "Bugfix release"

# Notes from changelog file
glab release create v1.0.1 -F CHANGELOG.md

# With release name and milestone
glab release create v1.0.1 -n "Version 1.0.1" -m "v1.0.1"

# Upload files as assets
glab release create v1.0.1 ./dist/app-linux.tar.gz ./dist/app-mac.tar.gz

# Upload with display names (append #)
glab release create v1.0.1 './dist/app-linux.tar.gz#Linux Build'

# Upload with display name and link type (append ## after name)
glab release create v1.0.1 './dist/app.tar.gz#App Package#package'

# Upload all files in a folder
glab release create v1.0.1 ./dist/*

# JSON asset links (for external URLs)
glab release create v1.0.1 --assets-links='[
  {"name": "Docs", "url": "https://docs.example.com/v1.0.1", "link_type": "other"},
  {"name": "Docker Image", "url": "https://registry.example.com/app:v1.0.1", "link_type": "image"}
]'

# Release from a specific commit
glab release create v1.0.1 --ref abc123def

# Release from a branch (creates tag automatically)
glab release create v1.0.1 --ref release/1.0

# Annotated tag with message
glab release create v1.0.1 -T "Release v1.0.1"

# Upload to package registry instead of generic storage
glab release create v1.0.1 ./dist/*.tar.gz --use-package-registry

# Set specific release date
glab release create v1.0.1 -D "2025-01-15T10:00:00Z"
```

### Asset Link Types

When specifying asset links via `--assets-links` JSON or the `#type` suffix:

| Type | Description |
|------|-------------|
| `other` | Generic link (default) |
| `package` | Package file |
| `image` | Container image |
| `runbook` | Runbook link |

## glab release list

List releases.

```bash
glab release list                   # List all releases
glab release list -F json           # JSON output
glab release list --per-page 10     # Limit results
```

## glab release view

View details of a specific release.

```bash
glab release view v1.0.1            # View by tag
glab release view v1.0.1 --web     # Open in browser
```

## glab release delete

Delete a release.

```bash
glab release delete v1.0.1                     # Delete release (keeps tag)
glab release delete v1.0.1 --with-tag          # Delete release and its tag
glab release delete v1.0.1 --yes               # Skip confirmation
```

## glab release download

Download release assets.

```bash
glab release download v1.0.1                   # Download all assets
glab release download v1.0.1 -n "app.tar.gz"   # Download specific asset by name
glab release download v1.0.1 -D ./downloads    # Download to specific directory
```

## glab release upload

Upload assets to an existing release.

```bash
glab release upload v1.0.1 ./dist/app.tar.gz
glab release upload v1.0.1 './dist/app.tar.gz#Linux Build#package'
glab release upload v1.0.1 --assets-links='[{"name":"Docs","url":"https://example.com"}]'
```

## Changelog — glab changelog

Generate changelogs.

```bash
glab changelog generate                         # Generate changelog
glab changelog generate --version v1.0.1        # For a specific version
```

## Common Patterns for Agents

### Full Release Workflow

```bash
# 1. Ensure tag is pushed
git tag v1.2.0
git push origin v1.2.0

# 2. Create release with notes and assets
glab release create v1.2.0 ./dist/*.tar.gz \
  -n "Version 1.2.0" \
  -F CHANGELOG.md \
  -m v1.2.0

# 3. Verify
glab release view v1.2.0
```

### Release from CI Pipeline

```bash
# In CI, create release from pipeline artifacts
glab release create v1.2.0 \
  --notes "Automated release from CI" \
  --ref $CI_COMMIT_SHA \
  ./build/artifacts/*
```

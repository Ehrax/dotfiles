# Actions & Releases — gh CLI Reference

## Workflow Runs

```bash
gh run list                          # Recent runs
gh run list --workflow deploy.yml    # Runs for specific workflow
gh run list --branch main            # Runs on a branch

gh run view                          # View latest run
gh run view 1234567                  # View specific run
gh run view --log                    # Show logs
gh run watch                         # Live-watch current run

gh run rerun 1234567                 # Rerun failed run
gh run rerun --failed                # Rerun only failed jobs
gh run cancel 1234567                # Cancel a run

gh run download 1234567              # Download artifacts
gh run download 1234567 -n my-artifact
```

## Workflows

```bash
gh workflow list                          # List workflows
gh workflow view deploy.yml               # View workflow details

gh workflow run deploy.yml                # Trigger manually
gh workflow run deploy.yml \
  --field environment=production          # With inputs

gh workflow enable deploy.yml
gh workflow disable deploy.yml
```

## Releases

```bash
# Create release with auto-generated notes
gh release create v1.2.0 \
  --generate-notes \
  --title "v1.2.0 — Auth improvements"

# Create with specific notes and assets
gh release create v1.2.0 ./dist/app.tar.gz ./dist/app.zip \
  --notes "$(cat <<'EOF'
## What's new
- feat(auth): OAuth2 login
- fix(dashboard): null pointer on empty data

## Breaking changes
None.
EOF
)"

# Draft release (not published yet)
gh release create v1.2.0 --draft --generate-notes

# Pre-release
gh release create v2.0.0-beta.1 --prerelease --generate-notes

# List releases
gh release list

# View release
gh release view v1.2.0

# Upload additional assets to existing release
gh release upload v1.2.0 ./dist/extra.tar.gz

# Delete release
gh release delete v1.2.0
```

## Secrets & Variables

```bash
# Secrets (write-only)
gh secret list
gh secret set MY_SECRET                    # Prompts for value
gh secret set MY_SECRET --body "value"
gh secret set MY_SECRET < secret.txt
gh secret delete MY_SECRET

# Environment secrets
gh secret set MY_SECRET --env production

# Actions variables (readable)
gh variable list
gh variable set MY_VAR --body "value"
gh variable get MY_VAR
gh variable delete MY_VAR
```

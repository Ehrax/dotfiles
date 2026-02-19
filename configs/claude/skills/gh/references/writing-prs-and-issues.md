# Writing PRs & Issues — Titles, Descriptions & Best Practices

Guidelines for writing clear, consistent, and actionable pull requests and issues on GitHub.

---

## Pull Request Titles

### Use Conventional Commits Format

```
<type>[optional scope]: <description>
```

**Examples:**
```
feat(auth): add OAuth2 login via Passport.js
fix(dashboard): resolve null pointer on empty dataset
chore(deps): upgrade axios to v1.7
docs(api): document pagination parameters
refactor(ui): extract Button into shared component
```

### Types

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code change with no feature/bug change |
| `test` | Adding or updating tests |
| `chore` | Maintenance, deps, config |
| `perf` | Performance improvement |
| `build` | Build system or external deps |
| `ci` | CI/CD configuration |

### Scope

A noun describing the affected area — `(auth)`, `(api)`, `(ui)`, `(db)`, `(checkout)`. Keep it short and consistent with the codebase's naming.

### Title Rules

- **Imperative mood**: "Add", "Fix", "Update" — not "Added", "Fixed", "Updated"
- **50-72 characters max** — readable in PR lists and notifications
- **No period at the end**
- **Breaking changes**: append `!` after type — `feat!: remove legacy endpoint`
- **Issue reference**: optionally append `(closes #123)` at the end

### Good vs Bad

| Bad | Good |
|-----|------|
| `bug fix` | `fix(auth): resolve null pointer in login` |
| `update code` | `refactor(api): extract middleware helpers` |
| `new feature` | `feat(dashboard): add real-time search filtering` |
| `fixed the thing` | `fix(cart): handle zero-quantity edge case` |
| `changes` | `chore(deps): bump eslint to v9` |

---

## Pull Request Body

Always include these three sections. Add optional sections as needed.

### Required Structure

```markdown
## Description
<!-- What does this PR do and why? 1-3 sentences. -->
Adds Google and GitHub OAuth2 login via Passport.js so users can sign in without creating a separate password.

Closes #123

## How to test
1. `npm install && npm run dev`
2. Navigate to `/login`
3. Click "Sign in with Google" — should redirect to Google OAuth consent screen
4. Authenticate and verify redirect back to `/dashboard`
5. Confirm session persists on page refresh

## Checklist
- [ ] Tests added/updated
- [ ] Docs updated
- [ ] Self-reviewed the diff
```

### Optional Sections

```markdown
## Screenshots / GIFs
<!-- For UI changes: before/after table -->
| Before | After |
|--------|-------|
| ![before](url) | ![after](url) |

## Breaking changes
- `BREAKING CHANGE:` Removed `legacyLogin()` — migrate to `login()` with the new `provider` arg.

## Notes for reviewer
<!-- Anything that needs extra attention or context -->
- The token refresh logic in `auth.js:87` is intentionally non-standard — see comment.
```

### Closing Issues

GitHub auto-closes issues on PR merge when the body contains:

| Keyword | Example |
|---------|---------|
| `Closes` | `Closes #123` |
| `Fixes` | `Fixes #123` |
| `Resolves` | `Resolves #123` |

Multiple issues: `Closes #123, closes #456`

### Creating PRs with gh

```bash
# Full non-interactive PR with heredoc body
gh pr create \
  --title "feat(auth): add OAuth2 login" \
  --body "$(cat <<'EOF'
## Description
Adds Google and GitHub OAuth2 login.

Closes #123

## How to test
1. Run `npm run dev`
2. Go to /login and click "Sign in with Google"
3. Verify redirect and session

## Checklist
- [x] Tests added
- [x] Docs updated
EOF
)"

# Fill from commit messages, then edit
gh pr create --fill

# Draft for early feedback
gh pr create --title "feat(api): v2 migration" --draft --fill

# PR targeting a specific base branch
gh pr create --title "fix(prod): hotfix null crash" --base main
```

---

## Issue Titles

### Format by Type

| Type | Format | Example |
|------|--------|---------|
| Bug | `[Bug]: <component> <symptom> <context>` | `[Bug]: Login button unresponsive on iOS Safari 17` |
| Feature | `[Feature]: <user story or capability>` | `[Feature]: Add dark mode toggle` |
| Docs | `[Docs]: <what to update>` | `[Docs]: Update CLI install guide for macOS` |
| Task | Imperative statement | `Refactor auth middleware to JWT v3` |
| Question | `[Question]: <specific question>` | `[Question]: Best way to handle rate limits?` |

### Title Rules

- **50-70 characters ideal**
- Sentence case — capitalize only the first word
- Specific: include component, symptom, and context when possible
- Avoid "not working", "broken", "issue with" — describe the actual problem

### Good vs Bad

| Bad | Good |
|-----|------|
| `Something broken` | `[Bug]: API returns 500 on POST /users with invalid email` |
| `Add feature` | `[Feature]: Support CSV export on the reports page` |
| `Login problem` | `[Bug]: Login fails after 30-min session timeout on mobile` |

---

## Issue Body

### Bug Report

```markdown
## Summary
The login button does nothing on iOS Safari 17 — no network request fires.

## Steps to reproduce
1. Open `/login` on iOS Safari 17
2. Fill in email and password
3. Tap "Sign in"

**Expected**: Form submits and redirects to dashboard.
**Actual**: Button tap has no visible effect.

## Environment
- Device: iPhone 15 Pro
- OS: iOS 17.4
- Browser: Safari 17
- App version: v2.3.1

## Additional context
- Happens 100% of the time on iOS Safari, never on Chrome
- Console error: `TypeError: Cannot read properties of null (reading 'submit')`
```

### Feature Request

```markdown
## Summary
As a user, I want a dark mode toggle so I can use the app comfortably at night.

## Use cases
- Evening/night usage without eye strain
- Users with light sensitivity

## Acceptance criteria
- [ ] Toggle available in user settings
- [ ] Preference persists across sessions
- [ ] Respects OS-level dark mode setting by default

## Alternatives considered
- CSS media query only (no manual toggle) — rejected, user control preferred
```

### Creating Issues with gh

```bash
# Bug report
gh issue create \
  --title "[Bug]: Login button unresponsive on iOS Safari 17" \
  --label "bug" \
  --body "$(cat <<'EOF'
## Summary
...

## Steps to reproduce
1. ...

**Expected**: ...
**Actual**: ...
EOF
)"

# Feature request
gh issue create \
  --title "[Feature]: Add CSV export to reports page" \
  --label "enhancement" \
  --assignee "@me"

# Assign to milestone and project
gh issue create \
  --title "Refactor auth middleware to JWT v3" \
  --milestone "v3.0" \
  --label "refactor"
```

---

## Quick Reference

### PR title formula
```
<type>(<scope>): <imperative description> [closes #N]
```

### PR body sections (always include)
1. **Description** — what + why + `Closes #N`
2. **How to test** — numbered steps anyone can follow
3. **Checklist** — tests, docs, self-review

### Issue title formula
```
[Type]: <component> <symptom/capability> <context>
```

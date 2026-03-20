# Writing Issues & Merge Requests — Titles, Descriptions & Best Practices

Guidelines for writing clear, scannable, and actionable issues and merge requests in GitLab.

## Issue Titles

### Be Descriptive and Specific

Make the title convey **at a glance** what the issue is about. Include key details like component/location, problem/action, frequency/scope, and outcome.

| Quality | Example |
|---------|---------|
| Good | `Login button unresponsive on iOS Safari 17 (1 in 5 attempts)` |
| Bad | `Something broken` or `Help!` |

### Use Action-Oriented or Problem-Statement Format

| Type | Format | Example |
|------|--------|---------|
| Bug | `[Bug]: <Component> <symptom> <context>` | `[Bug]: API returns 500 on POST /users with invalid email` |
| Feature | `[Feature]: <User story>` | `[Feature]: Add dark mode toggle for accessibility` |
| Docs | `[Docs]: <What to update>` | `[Docs]: Update CLI installation guide for macOS` |
| Question | `[Question]: <Specific question>` | `[Question]: Best way to handle rate limiting?` |
| Task | Imperative statement | `Refactor auth middleware to use JWT v3` |

### Keep It Concise (50-70 Characters Ideal)

- Use sentence case (capitalize first word, not every word).
- Avoid fluff: no "Issue:", "Problem with:", or vague terms like "not working."
- Don't cram labels into the title — apply them as actual labels instead.

### Follow the "Frequency + Location + Problem" Rule

| Element | Example |
|---------|---------|
| Frequency | Occasionally, Always, On load |
| Location | `/login page`, `src/utils/api.js` |
| Problem | Crashes, Returns 404 |

Combined: `Search results empty on /products page after v2.1.0 update`

### Creating Issues with glab

```bash
# Good: descriptive title, labels, milestone
glab issue create \
  -t "[Bug]: Profile image fails to upload on Android" \
  -l bug,P1 \
  -m v2.1

# Good: feature with clear user story
glab issue create \
  -t "[Feature]: Support OAuth2 for third-party auth" \
  -l enhancement \
  -d "As a user, I want to log in with Google/GitHub so I don't need another password."
```

## Issue Descriptions

Every issue body should be structured, scannable, and actionable. Use markdown headings, checklists, and code blocks. Adapt the sections below to the issue type.

### Standard Issue Body Structure

```markdown
## Summary
1-2 sentences: What and why.
User story format: "As a [user], I want [goal] so that [benefit]."

## Steps to Reproduce (bugs)
1. Go to /login
2. Enter invalid email
3. Click submit
4. Observe 500 error

**Expected**: Form shows validation error.
**Actual**: Page returns HTTP 500.

## Environment (bugs)
- OS: macOS 15
- Browser: Safari 18.2
- App version: v2.1.0
- Node: v20.10

## Additional Context
- Logs: ```paste here```
- Screenshots/GIFs: ![description](url)
- Frequency: "Crashes 3/5 times on mobile"

## Acceptance Criteria (features)
- [ ] Users can toggle dark mode from settings
- [ ] Preference persists across sessions
- [ ] Respects OS-level dark mode setting

## Suggested Fix / Next Steps (optional)
- [ ] Research alternative approach
- [ ] Draft MR

## Related Issues
Closes #123, Related #456, Depends on #789
```

### Sections by Issue Type

| Type | Key Sections | Tips |
|------|-------------|------|
| **Bug** | Repro steps, Expected/Actual, Environment, Logs/Screenshots, Frequency | Provide a minimal repro (link to sandbox, branch, or snippet); quantify: "Happens 100% on mobile" |
| **Feature** | User story, Use cases, Alternatives considered, Mockups | Include wireframes or design links; list edge cases |
| **Docs** | What to document, Current broken link/section, Proposed text | Show before/after diff |
| **Question** | What you've tried, Error messages, Goal | Consider using GitLab Discussions if exploratory |
| **Task/Epic** | Overview, Sub-tasks (checklist), Dependencies, Acceptance criteria | Link sub-issues; define "Definition of Done" |

### Essential Formatting Elements

| Element | Use Case | Syntax |
|---------|----------|--------|
| Headings | Section breaks | `## H2` |
| Task lists | Track progress, acceptance criteria | `- [ ] Task` |
| Code blocks | Errors, commands, logs | ` ```bash command ``` ` |
| Images | Screenshots, GIFs | `![alt](url)` or drag-drop in GitLab UI |
| References | Link issues, MRs, users | `#123`, `group/project#456`, `@username` |
| Tables | Structured data, comparisons | Markdown tables |

### Content Quality Rules

**Be specific and quantify:**

| Bad | Good |
|-----|------|
| "It's broken" | "Button fails to submit on /login (Safari 18)" |
| "Sometimes crashes" | "Crashes 3/5 times when uploading files > 10MB" |
| No repro steps | Numbered steps + minimal repro link |
| Wall of text | Headings + bullets + code blocks |
| No environment info | Full specs (OS, browser, version, config) |
| Attachments only | Inline screenshots + written description |

**Search before creating**: Check for duplicates with `glab issue list -s "keyword"`. Reference related issues: "Searched #123, #456 — this is different because..."

**Use task lists for progress tracking**: GitLab renders `- [ ]` checkboxes interactively. For large features, create sub-issues and link them.

### Writing Descriptions with glab

```bash
# Open editor for structured description
glab issue create \
  -t "[Bug]: Profile upload fails on Android" \
  -l bug,P1 \
  -d -

# Inline description for simple issues
glab issue create \
  -t "[Feature]: Support OAuth2 for third-party auth" \
  -l enhancement \
  -d "As a user, I want to log in with Google/GitHub so I don't need another password.

## Use Cases
- Users with existing Google accounts can skip registration
- Reduces password fatigue

## Acceptance Criteria
- [ ] Google OAuth2 login works
- [ ] GitHub OAuth2 login works
- [ ] Existing email users can link accounts"

# Create with linked issues
glab issue create \
  -t "Refactor auth middleware to use JWT v3" \
  -l refactor \
  -d "Depends on #42. Blocked by #55." \
  --linked-issues 42,55 --link-type relates_to
```

## Merge Request Titles

### Use Imperative Mood with Conventional Commits Prefix

Start with `<type>[optional scope]: <description>` for automation and scannable changelogs.

**Common types:**

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance, deps, config |
| `perf` | Performance improvement |
| `build` | Build system or external deps |
| `ci` | CI/CD configuration |

**Scope**: Noun describing affected area — `(ui)`, `(api)`, `(auth)`, `(db)`.

### Title Rules

- **Length**: 50-72 characters max — scannable in lists and notifications.
- **Imperative mood**: "Add", "Fix", "Update" — not "Added", "Fixes", "Updated".
- **Include issue references**: `(closes #123)` or `(#123)`.
- **Breaking changes**: Use `!` after type — `feat!: drop Node 18 support`.

### Good vs Bad Titles

| Bad | Good |
|-----|------|
| `bug fix` | `fix(auth): resolve null pointer in login` |
| `update code` | `refactor(api): extract middleware utils` |
| `MR for new feature` | `feat(dashboard): add search (closes #456)` |
| `fixed the login` | `fix(login): handle invalid email edge case` |
| `changes` | `chore(deps): upgrade axios to v1.7` |

### Creating MRs with glab

```bash
# Good: conventional title, labels, reviewer
glab mr create \
  -t "fix(auth): resolve null pointer in login (closes #123)" \
  -l bug,reviewed \
  --reviewer teamlead \
  -b main

# Good: feature MR linked to issue
glab mr create \
  -t "feat(dashboard): add real-time search filtering" \
  --related-issue 456 \
  --copy-issue-labels \
  --fill

# Draft MR for early feedback
glab mr create \
  -t "feat(api): v2 endpoint migration" \
  --draft \
  --label RFC
```

## Commit Message Conventions

Individual commit messages follow similar rules to MR titles but apply at the commit level.

### Subject Line

- **Max 72 characters** — truncated in `git log --oneline` and GitLab UI otherwise.
- **Capital letter**: Start with uppercase ("Add", not "add").
- **Imperative mood**: Write as a command ("Fix bug", not "Fixed bug" or "Fixes bug").
- **No trailing period**: The subject is a title, not a sentence.
- **Conventional prefix**: Match the MR type — `feat:`, `fix:`, `docs:`, etc.

### Body (Optional)

- **Blank line** between subject and body.
- **Max 72 characters per line** — wrap manually for readability in terminals.
- **Explain "what" and "why"**, not "how" — the diff shows how.

### Good vs Bad Commits

| Bad | Good |
|-----|------|
| `fixed stuff` | `fix(auth): handle expired token on refresh` |
| `wip` | `feat(search): add autocomplete suggestions` |
| `changes` | `refactor(api): extract validation middleware` |
| `Updated the tests and also fixed a bug in login and refactored the auth module` | Split into 3 separate commits |

### Tip

If a commit message needs "and" to describe what it does, consider splitting it into multiple commits.

## Merge Request Descriptions

Structure with these sections:

```markdown
### What does this MR do?
High-level summary + why (problem solved, user story).
Link to related issues: `Closes #123`

### Changes
- Bullet list of key changes
- One change per bullet
- Group by area if touching multiple components

### How to test
1. Check out this branch
2. Run `npm install && npm run dev`
3. Navigate to /login
4. Verify button responds within 200ms

### Screenshots / GIFs (REQUIRED for UI changes)
| Before | After |
|--------|-------|
| ![before](url) | ![after](url) |

### Breaking changes (if any)
- `BREAKING CHANGE:` description
- Migration steps

### Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Passes CI pipeline
- [ ] Self-reviewed the diff
```

### Using Description with glab

```bash
# Open editor for longer descriptions
glab mr create -t "feat(search): add filters" -d -

# Description inline (short)
glab mr create \
  -t "fix(login): handle timeout" \
  -d "Closes #42. Adds 30s timeout with retry logic for the auth endpoint."
```

## Draft Merge Requests

Use draft MRs to signal work-in-progress and prevent accidental merging during review.

### How to Create

```bash
# Flag on creation
glab mr create -t "feat(api): v2 endpoint migration" --draft

# Or prefix the title manually
glab mr create -t "Draft: feat(api): v2 endpoint migration"
```

- **`--draft` flag** or **`Draft:` prefix**: Both mark the MR as draft in GitLab.
- **`WIP:` prefix is deprecated**: GitLab still recognizes it, but `Draft:` is the current convention.
- **Prevents merging**: Draft MRs cannot be merged until marked as ready.
- **Mark ready**: Use `glab mr update <id> --ready` or remove the `Draft:` prefix.

### When to Use

- Early feedback before implementation is complete
- CI validation on partial work
- Reserving an MR number for linking from issues
- Collaborative development where others may push to the branch

## Description Templates

GitLab supports description templates that auto-populate when creating issues or MRs.

### Template Locations

```
.gitlab/
├── issue_templates/
│   ├── Default.md          # Auto-populates for all new issues
│   ├── Bug.md
│   └── Feature.md
└── merge_request_templates/
    ├── Default.md          # Auto-populates for all new MRs
    └── Hotfix.md
```

- **`Default.md`**: Automatically populates the description field for new issues/MRs.
- **Named templates**: Users select from a dropdown in the GitLab UI.

### Quick Actions in Templates

Templates can include [quick actions](https://docs.gitlab.com/ee/user/project/quick_actions.html) that execute when the issue/MR is created:

```markdown
/label ~bug ~P1
/assign @me
/milestone %v2.0
```

### Template Variables

MR templates support these variables that GitLab auto-expands:

| Variable | Expands to |
|----------|-----------|
| `%{source_branch}` | Source branch name |
| `%{target_branch}` | Target branch name |
| `%{first_commit}` | First commit message in the MR |
| `%{title}` | MR title |

### Using Templates with glab

When templates exist, `glab mr create` and `glab issue create` auto-populate from `Default.md`. To use a named template:

```bash
# glab doesn't have a --template flag, but you can pipe template content:
cat .gitlab/merge_request_templates/Hotfix.md | glab mr create -t "fix(auth): patch token leak" -d -
```

## Keep MRs Small and Focused

- **Single purpose**: One MR = one feature or fix.
- **Self-review first**: Run `glab mr diff` before requesting review.
- **Use stacked diffs** (`glab stack`) for large features that need multiple sequential MRs.
- **Commit count**: Aim for fewer than 10 commits per MR. If you have more, consider squashing related commits.
- **Line count**: If an MR exceeds ~500 changed lines, add a note in the description explaining the scope and why it can't be split.
- **Squash-and-merge**: For MRs with messy commit history, use squash merge to produce a clean single commit on the target branch. GitLab supports this as a merge option.

## Linking Issues and MRs

GitLab auto-closes issues when MRs merge if the description contains closing keywords:

| Keyword | Example |
|---------|---------|
| `Closes` | `Closes #123` |
| `Fixes` | `Fixes #123` |
| `Resolves` | `Resolves #123` |

These work in MR descriptions and commit messages. Multiple issues: `Closes #123, closes #456`.

With glab:

```bash
# MR linked to issue (adds closing reference automatically)
glab mr create --related-issue 123 --fill

# Or include in description manually
glab mr create -t "fix(auth): handle timeout" -d "Fixes #42"
```

## Labels Instead of Title Prefixes

While `[Bug]:` prefixes are useful when templates aren't available, prefer applying labels separately for better filtering:

```bash
# Labels are filterable; title prefixes are not
glab issue create -t "API returns 500 on invalid email" -l bug,P1,api
glab mr create -t "fix(api): validate email before POST" -l bug,api
```

Use title prefixes (`[Bug]:`, `[Feature]:`) only when the project convention requires them or no label system is in place.

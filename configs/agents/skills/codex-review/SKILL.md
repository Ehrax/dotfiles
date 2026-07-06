---
name: codex-review
description: Run a Codex (gpt-5.5) code review of uncommitted changes, a branch diff, or a single commit, then relay only verified findings. Use when the user asks for a codex review or an independent second-model review of changes, or another skill needs a review gate before shipping.
---

# Codex Review

An independent review by gpt-5.5 via `codex review`, with you as the filter: Codex finds, you verify, only confirmed findings reach the user. CLI mechanics (effort, background runs, resume) live in the `codex` skill.

## Workflow

### 1. Identify the review target

Uncommitted changes, branch vs base, a single commit, or a focused concern ("error handling in the payment path"). Ask only if genuinely ambiguous.

### 2. Run the review

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"

# Staged + unstaged + untracked
codex -C "$REPO" review --uncommitted </dev/null > "$ARTIFACT_DIR/report.md"

# Current branch against a base branch
codex -C "$REPO" review --base main </dev/null > "$ARTIFACT_DIR/report.md"

# A single commit
codex -C "$REPO" review --commit <sha> </dev/null > "$ARTIFACT_DIR/report.md"

# Custom instructions — reviews the working tree by default
codex -C "$REPO" review "<review prompt>" </dev/null > "$ARTIFACT_DIR/report.md"
```

**Target flags and a custom prompt are mutually exclusive** (`--uncommitted`/`--base`/`--commit` with a prompt → `error: the argument '--uncommitted' cannot be used with '[PROMPT]'`). Want both a specific target and a focus? Use the prompt form and name the target inside the prompt ("review only the uncommitted diff, focus on …").

Steer via `-c` (`-c model_reasoning_effort=medium` for quick passes; the `-m` flag doesn't exist on `review`). Real reviews at `xhigh` take minutes — run in the background. Done when the process exits 0 and the report is non-empty.

### 3. Verify before relaying

Findings arrive as priority bullets (`[P1]`–`[P3]`) anchored to `file:line` with a failure scenario. Before presenting a finding, inspect the cited code or diff enough to decide whether it is real. Complete when every finding you relay is marked either confirmed (you checked) or unverified (Codex's claim, stated as such).

### 4. Report back

- Confirmed issues first, ranked by severity; unverified Codex suggestions clearly separated.
- If Codex finds nothing: say so and name which target it inspected, plus any residual test gaps you see yourself.
- If `codex` is missing or the command fails: report the error and offer to review the changes directly.

## Review prompt (for the prompt form)

```text
Review only <target> for bugs, regressions, missing tests, security issues, and requirement mismatches.

Prioritize findings over summary. For each finding include:
- severity
- file and line reference
- concrete failure mode
- suggested fix direction

Do not edit files. If there are no substantive findings, say so and name any residual test gaps.
```

Add task-specific context when useful: requirements, risky areas, expected behavior, relevant tests, or files you are unsure about.

---
name: codex
description: Drive the Codex CLI to delegate coding work to a second model — headless implementation via `codex exec`, code review via `codex review`, steering and resuming Codex sessions. Use when the user mentions Codex, wants implementation or review work offloaded to another model, or another skill needs to run the codex CLI.
---

# Codex CLI

Delegate work to Codex (OpenAI's coding agent) and stay the foreman: you scope the job, Codex executes headlessly, you verify and integrate.

Verified against `codex-cli 0.142.4` — on a version bump, re-check flags with `codex exec --help`.

## Defaults on this machine

`~/.codex/config.toml` is machine-local and not tracked in dotfiles. On this machine it sets model `gpt-5.5` at reasoning effort `xhigh`. `codex exec` runs with approval `never`.

**Always pass the sandbox explicitly** (`-s workspace-write` or `-s read-only` on exec; `-c sandbox_mode="..."` on resume). Observed in practice: with no flag, the header showed `workspace-write` — config can override the documented read-only default, so a "read-only" review run without an explicit flag may be writable. Check the header, don't assume.

## Workflow

### 1. Write the brief

The prompt you hand Codex. Complete when it names:

- the goal, in one sentence
- files/dirs in scope, and fences — what must not be touched
- the exact verification command (test/lint/build)
- the done criterion Codex must satisfy before reporting back

Codex auto-reads `AGENTS.md` (its CLAUDE.md) — don't restate what's already there. Codex also loads the same skills folder as Claude (shared symlink), so a brief can tell it to use a skill by name.

### 2. Launch

Implementation:

```bash
codex exec -C <repo> -s workspace-write -o "$SCRATCH/codex-last.md" "<brief>" </dev/null
```

Review — two modes, pick by how much steering you need:

**Rubric-driven review (preferred for quality gates):** a read-only `codex exec` with the rubric as its prompt. Codex loads the same skills folder as Claude, so the prompt can say "load and apply the <skill-name> skill as your rubric". Demand findings-only output with severity prefixes anchored to `file:line`:

```bash
codex exec -C <repo> -s read-only -o "$SCRATCH/review.md" "Load and apply the <rubric-skill> skill. Review git diff main...HEAD. FINDINGS ONLY, no edits: [BLOCKING]/[ADVISORY] bullets anchored to file:line. If nothing blocks, start with APPROVED." </dev/null
```

**Quick built-in review** (`codex review` — the subcommand has no `-m`/`-o`, but top-level `-C` works; steer via `-c`, capture stdout):

```bash
codex -C <repo> review --uncommitted     # staged + unstaged + untracked
codex -C <repo> review --base main       # diff against a base branch
codex -C <repo> review --commit <sha>    # a single commit
codex -C <repo> review "<instructions>"  # custom focus — CANNOT combine with a target flag; name the target inside the prompt instead
```

Built-in findings arrive on stdout as priority bullets (`[P1]`–`[P3]`) anchored to `file:line`. Full review ritual (prompt template, verify-before-relay, reporting rules): the `codex-review` skill.

- Always append `</dev/null` — with piped stdin, `codex exec` blocks on "Reading additional input from stdin…".
- `-o` writes Codex's final message to a file: the reliable way to capture the result.
- Grab the `session id:` line from the header output — you need it to iterate (step 4).
- Runs take minutes at `xhigh` effort — launch with `run_in_background` and monitor rather than blocking.

Launched when the header (workdir/model/sandbox/`session id:`) appears — check it ~15s after a background launch; a flag error exits 2 instantly with no header.

**Exit 0 ≠ task done.** Codex exits 0 whenever it finishes *talking*, including "I could not commit because X" and other partial completions. The `-o` file is a report, not a success signal — read it, then verify repo state yourself.

### 3. Verify

Foreman rule: Codex's own report counts for nothing until

- `git diff` is inspected and every touched file sits inside the brief's fences, and
- the brief's verification command passes, run by you.

Verification fails → step 4.

### 4. Iterate — resume, don't restart

```bash
codex exec resume <session-id> "<feedback>" </dev/null
codex exec resume --last "<feedback>" </dev/null    # most recent session in this cwd
```

A fresh `codex exec` throws away Codex's context; resume keeps it. Resume filters sessions by cwd — add `--all` to widen. Sessions survive the parent process being killed mid-run: work on disk stays, and `resume --last` continues with full memory — resume after crashes instead of restarting.

**Resume takes almost none of exec's flags** — no `-s`, no `--add-dir`, no `-o` (exit 2: `unexpected argument`). Everything goes through `-c`:

```bash
cd <worktree> && codex exec resume --last \
  -c sandbox_mode="workspace-write" \
  -c model_reasoning_effort="medium" \
  -c sandbox_workspace_write.network_access=true \
  -c 'sandbox_workspace_write.writable_roots=["<pnpm-store>","<repo>/.git"]' \
  "<feedback>" </dev/null
```

No `-o` on resume — capture stdout instead.

## Steering levers

| Lever | Flag |
|---|---|
| Model | `-m <model>` for exec; `-c model="<model>"` for review (default `gpt-5.5` from config) |
| Effort | `-c model_reasoning_effort=medium` — drop from `xhigh` for mechanical tasks, large latency win |
| Network inside sandbox (installs, fetches) | `-c sandbox_workspace_write.network_access=true` |
| Extra writable dirs | `--add-dir <dir>` |
| Attach images/screenshots | `-i <file>` |
| Structured final answer | `--output-schema <schema.json>` |
| Machine-readable event stream | `--json` (JSONL on stdout) |
| Live web search | `--search` |
| Outside a git repo | `--skip-git-repo-check` |
| Don't persist the session | `--ephemeral` |

Parallel fan-out: one `codex exec` per git worktree — concurrent writers in one checkout conflict. Proven at 3 concurrent execs incl. parallel `pnpm install` (no store contention).

**Worktree sandbox trap:** a worktree's real gitdir lives in the main repo (`<repo>/.git/worktrees/<name>`), *outside* the workspace sandbox — `git add`/`commit` fail with `Operation not permitted` on `index.lock`. Add `--add-dir <main-repo>/.git` (exec) or put it in `writable_roots` (resume) so Codex can commit its own work. Same idea for package managers: `--add-dir $(pnpm store path)` or installs fail.

**Do not wrap codex in fire-and-forget subagents.** A subagent that launches codex in the background and then ends its turn gets finalized — and finalization kills its child processes, taking the codex run down mid-flight. Dispatch codex directly from your own loop with background Bash, or have a wrapper block until codex exits.

Never use `--dangerously-bypass-approvals-and-sandbox` on this machine. `workspace-write` plus network access covers everything short of system-level changes — do those yourself.

## GUI / computer-use / browser tasks

`$computer-use` operates **any** Mac app — screenshot + accessibility tree (`get_app_state`), `click`, `type_text`, `set_value`, `scroll`, `drag`, `press_key` — and **works headlessly** for any app that has been trusted once with "Always allow". Verified end-to-end: headless `codex exec` opened Notes, created a note, typed into it, and screenshot-verified the result.

Per-app trust is the only gate. An untrusted app fails with `Computer Use approval denied via MCP elicitation for app '<bundle-id>'`. Unlock it once by driving the TUI through tmux and answering the approval yourself:

```bash
tmux new-session -d -s cu -x 200 -y 50
tmux send-keys -t cu "codex '\$computer-use take a screenshot of <App>'" Enter
# poll: tmux capture-pane -t cu -p   → until the "Allow Codex to use <App>?" menu appears
tmux send-keys -t cu Down Enter      # selects "2. Always allow" (persists; plain "Allow" does NOT)
# poll until done, then: tmux kill-session -t cu
```

After that, every future headless run controls that app directly. `$browser` (in-app browser/Chrome) is the exception: its backends bind to the interactive app session — `agent.browsers.list()` is `[]` under `exec` — so browser-plugin work stays in interactive Codex. Details, tool list, and error signatures: REFERENCE.md.

## Gotchas

- Startup warnings (plugin hooks parse failure, "skills context budget") are noise, not errors. So is "Reading additional input from stdin…" when stdin is `</dev/null` — it prints the line, hits EOF, proceeds.
- The harness environment can set `FORCE_COLOR` and `NO_COLOR` together, which makes Node print a startup warning to stderr in spawned child processes — breaking empty-stderr assertions in CLI tests. Tell Codex (and run your own verification) with `env -u FORCE_COLOR`.
- Real implementation runs at `medium` effort take 10–40 min and ~100k–300k tokens; always `run_in_background` and validate the startup header rather than waiting inline.
- `codex apply <TASK_ID>` applies Codex **Cloud** task diffs — it does not apply local session work.

Full subcommand map, config keys, and sandbox/approval semantics: [REFERENCE.md](REFERENCE.md).

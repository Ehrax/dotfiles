---
name: codex-cli
description: Manually invoked playbook for driving the Codex CLI — headless implementation via `codex exec`, code review via `codex review`, computer use, and steering or resuming Codex sessions. Use only when the user explicitly invokes the codex-cli skill or explicitly asks the orchestrator to use Codex. Codex-based computer use is also explicit-only. Do not auto-trigger for ordinary implementation, review, delegation, model-selection, GUI/browser work, or incidental mentions of Codex.
disable-model-invocation: true
---

# Codex CLI

Delegate work to Codex (OpenAI's coding agent) and stay the foreman: you scope the job, Codex executes headlessly, you verify and integrate.

Verified against `codex-cli 0.144.6` — on a version bump, re-check `codex exec --help`, `codex exec resume --help`, and the review subcommands.

Since 0.144.6: `--search` is a TOP-LEVEL flag, not an `exec` flag — `codex -a never --search exec ...` works, `codex exec --search` exits 2. The startup-header ERROR line about `codex_models_manager::cache … missing field` is noise, not a failure.

## Pin execution policy; choose models per task

`~/.codex/config.toml` is machine-local and changes over time. Never encode its current model or reasoning effort in this skill. The Chief chooses the model/effort from the canonical [model routing table](../../model-table.md), task stakes, and observed output quality; pass them explicitly when reproducibility matters. Escalate or retry based on evidence rather than preserving a stale global default.

Always pin approval and sandbox explicitly. Use top-level `codex -a never exec ...` for headless work, plus `-s workspace-write` or `-s read-only` on `exec`. Resume has no `-s`; use `-c sandbox_mode="..."`. Check the startup header/event stream and never infer policy from machine config.

## Workflow

### 1. Write the brief

The prompt you hand Codex. Complete when it names:

- the goal, in one sentence
- files/dirs in scope, and fences — what must not be touched
- the exact verification command (test/lint/build)
- the done criterion Codex must satisfy before reporting back

Codex auto-reads `AGENTS.md` (its CLAUDE.md) — don't restate what's already there. Codex also loads the same skills folder as Claude (shared symlink), so a brief can tell it to use a skill by name.

### 2. Launch

Implementation (the Chief selects `<model>` and `<effort>` for this slice):

```bash
codex -a never exec \
  -C <worktree> \
  -s workspace-write \
  -m <model> \
  -c model_reasoning_effort=<effort> \
  -o "$SCRATCH/codex-last.md" \
  "<brief>" </dev/null
```

The Chief launches and owns the long-running process directly. A persisted CLI session is a resumable headless executor; do not claim it is a visible Codex Desktop sidebar task unless that behavior has been separately proven in the current app version.

Review — two modes, pick by how much steering you need:

**Rubric-driven review (preferred for quality gates):** a read-only `codex exec` with the rubric as its prompt. Codex loads the same skills folder as Claude, so the prompt can say "load and apply the <skill-name> skill as your rubric". Demand findings-only output with severity prefixes anchored to `file:line`:

```bash
codex -a never exec -C <repo> -s read-only -m <review-model> -o "$SCRATCH/review.md" "Load and apply the <rubric-skill> skill. Review git diff main...HEAD. FINDINGS ONLY, no edits: [BLOCKING]/[ADVISORY] bullets anchored to file:line. If nothing blocks, start with APPROVED." </dev/null
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
- Capture the `session id:` line from the header or the equivalent `--json` event — you need the exact id to iterate safely (step 4).
- Runs can take minutes. Use the harness's owned background/session mechanism and poll it; do not block the Chief's communication loop for long stretches.

Launched when the header (workdir/model/sandbox/`session id:`) appears — check it ~15s after a background launch; a flag error exits 2 instantly with no header.

**Exit 0 ≠ task done.** Codex exits 0 whenever it finishes *talking*, including "I could not commit because X" and other partial completions. The `-o` file is a report, not a success signal — read it, then verify repo state yourself.

### 3. Verify

Foreman rule: Codex's own report counts for nothing until

- `git diff` is inspected and every touched file sits inside the brief's fences, and
- the brief's verification command passes, run by the Chief, and
- a fresh independent review clears the required severity gate.

The executor does not commit by default. After verification and review, the Chief stages, commits, integrates, and removes the temporary worktree/branch. Give an executor commit authority only when the brief says so explicitly; then add the worktree gitdir writable root and still independently verify the commit.

Verification fails → step 4.

### 4. Iterate — resume, don't restart

```bash
codex -a never exec resume <session-id> "<feedback>" </dev/null
codex -a never exec resume --last "<feedback>" </dev/null    # most recent session in this cwd
```

A fresh `codex exec` throws away Codex's context; resume keeps it. Prefer the captured session id: `--last` is ambiguous when several executors run concurrently. Resume filters sessions by cwd — add `--all` to widen. Sessions survive ordinary parent-process interruption: work on disk stays and the persisted session can be resumed instead of restarted.

Resume in 0.144.1 accepts `-m`, `-o`, `-i`, `--json`, `--output-schema`, and related session flags. It still accepts neither `-s` nor `--add-dir`; sandbox and additional writable roots go through `-c`. Outside a git repo, resume needs `--skip-git-repo-check` just like exec — without it, it exits 1 ("Not inside a trusted directory") even though the original session already ran there:

```bash
cd <worktree> && codex -a never exec resume <session-id> \
  -m <model> \
  -o "$SCRATCH/codex-resume-last.md" \
  -c sandbox_mode="workspace-write" \
  -c model_reasoning_effort="<effort>" \
  -c sandbox_workspace_write.network_access=true \
  -c 'sandbox_workspace_write.writable_roots=["<pnpm-store>","<repo>/.git"]' \
  "<feedback>" </dev/null
```

## Steering levers

| Lever | Flag |
|---|---|
| Model | Chief-selected `-m <model>` for `exec`/`exec resume`; use `-c model="<model>"` where only config overrides exist |
| Effort | Chief-selected `-c model_reasoning_effort=<effort>` based on stakes, difficulty, and observed quality |
| Network inside sandbox (installs, fetches) | `-c sandbox_workspace_write.network_access=true` |
| Extra writable dirs | `--add-dir <dir>` |
| Attach images/screenshots | `-i <file>` |
| Structured final answer | `--output-schema <schema.json>` |
| Machine-readable event stream | `--json` (JSONL on stdout) |
| Live web search | `--search` |
| Outside a git repo | `--skip-git-repo-check` |
| Don't persist the session | `--ephemeral` |

Parallel fan-out: one `codex exec` per git worktree — concurrent writers in one checkout conflict. Proven at 3 concurrent execs incl. parallel `pnpm install` (no store contention).

### Chief + subagents

The Chief may use internal subagents concurrently for bounded read-only research, brief/golden checks, test-log inspection, failure reproduction, and independent review. This support fan-out should reduce Chief latency without giving multiple writers the same checkout. Each writing Codex executor still owns exactly one temporary worktree and file fence.

Launch the long-running `codex exec` from the Chief's own process/session loop. A subagent may wrap Codex only when it blocks until Codex exits and returns the complete session id/report; never let a wrapper background Codex and then finish its own turn. For GUI/computer-use acceptance, use at most one operator at a time after deterministic gates are green.

**Worktree sandbox trap:** a worktree's real gitdir lives in the main repo (`<repo>/.git/worktrees/<name>`), *outside* the workspace sandbox — `git add`/`commit` fail with `Operation not permitted` on `index.lock`. Add `--add-dir <main-repo>/.git` (exec) or put it in `writable_roots` (resume) so Codex can commit its own work. Same idea for package managers: `--add-dir $(pnpm store path)` or installs fail.

**Do not wrap Codex in fire-and-forget subagents.** A subagent that launches Codex in the background and then ends its turn gets finalized — and finalization kills its child processes, taking the Codex run down mid-flight. Dispatch Codex directly from the Chief's owned loop, or have a wrapper block until Codex exits.

Never use `--dangerously-bypass-approvals-and-sandbox` on this machine. `workspace-write` plus network access covers everything short of system-level changes — do those yourself.

## GUI / computer-use / browser tasks

**Manual gate:** use Codex for computer-use, GUI, or browser work only when the user explicitly asks for Codex-based computer use. A task merely benefiting from screenshots, clicking, visual verification, or browser interaction is not enough to route it through Codex.

`$computer-use` operates **any** Mac app — screenshot + accessibility tree (`get_app_state`), `click`, `type_text`, `set_value`, `scroll`, `drag`, `press_key` — and **works headlessly** for any app that has been trusted once with "Always allow". Verified end-to-end: headless `codex exec` opened Notes, created a note, typed into it, and screenshot-verified the result.

Per-app trust is the only gate. An untrusted app fails with `Computer Use approval denied via MCP elicitation for app '<bundle-id>'`. Unlock it once by driving the TUI through tmux and answering the approval yourself:

```bash
tmux new-session -d -s cu -x 200 -y 50
tmux send-keys -t cu "codex '\$computer-use take a screenshot of <App>'" Enter
# poll: tmux capture-pane -t cu -p   → until the "Allow Codex to use <App>?" menu appears
tmux send-keys -t cu Down Enter      # selects "2. Always allow" (persists; plain "Allow" does NOT)
# poll until done, then: tmux kill-session -t cu
```

After that, every future headless run controls that app directly. The Chief may delegate an explicitly user-authorized computer-use gate to one blocking subagent/operator, but never run multiple GUI operators concurrently. `$browser` (in-app browser/Chrome) is the exception: its backends bind to the interactive app session — `agent.browsers.list()` is `[]` under `exec` — so browser-plugin work stays in interactive Codex. Details, tool list, and error signatures: REFERENCE.md.

## Gotchas

- Startup warnings (plugin hooks parse failure, "skills context budget") are noise, not errors. So is "Reading additional input from stdin…" when stdin is `</dev/null` — it prints the line, hits EOF, proceeds.
- The harness environment can set `FORCE_COLOR` and `NO_COLOR` together, which makes Node print a startup warning to stderr in spawned child processes — breaking empty-stderr assertions in CLI tests. Tell Codex (and run your own verification) with `env -u FORCE_COLOR`.
- Real implementation runs may take 10–40 minutes and substantial tokens; use an owned background/session mechanism and validate the startup header rather than waiting inline.
- `codex apply <TASK_ID>` applies Codex **Cloud** task diffs — it does not apply local session work.

Full subcommand map, config keys, and sandbox/approval semantics: [REFERENCE.md](REFERENCE.md).

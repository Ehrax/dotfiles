# Codex CLI Reference

Verified against `codex-cli 0.142.4`.

## Subcommand map

| Command | Purpose |
|---|---|
| `codex` | Interactive TUI (options forwarded; optional `[PROMPT]` starts the session) |
| `codex exec` (`e`) | Run non-interactively — the delegation workhorse |
| `codex exec resume` | Resume a session by id/thread-name, or `--last` |
| `codex review` | Non-interactive code review of the current repo |
| `codex resume` / `fork` | Interactive session picker; `fork` branches a copy, `--last` skips the picker |
| `codex archive` / `unarchive` / `delete` | Manage saved sessions by id or name |
| `codex apply` (`a`) | `git apply` the diff of a Codex **Cloud** task to the working tree |
| `codex cloud` | Browse Codex Cloud tasks and apply changes locally (experimental) |
| `codex login` / `logout` | Manage auth |
| `codex mcp` | Manage external MCP servers Codex can call |
| `codex mcp-server` | Run Codex itself as an MCP server (stdio) — expose Codex as a tool to other agents |
| `codex plugin` | Manage plugins |
| `codex sandbox <cmd>` | Run an arbitrary command under Codex's seatbelt sandbox (`-P` profile, `--log-denials`) |
| `codex doctor` | Diagnose install, config, auth, runtime health |
| `codex update` | Self-update |
| `codex features` | Inspect feature flags |
| `codex completion` | Shell completion scripts |
| `codex app-server` / `remote-control` / `exec-server` / `app` / `debug` | Desktop-app and experimental plumbing — not needed for delegation |

## Sandbox modes (`-s, --sandbox`)

| Mode | Semantics |
|---|---|
| `read-only` | Read anywhere; no writes, no network. **Default for `exec`.** |
| `workspace-write` | Write inside the workdir (`-C`), `--add-dir` dirs, and temp dirs. Network **off** unless `-c sandbox_workspace_write.network_access=true`. |
| `danger-full-access` | No sandbox. Only inside an externally sandboxed environment. |

## Approval policies (`-a, --ask-for-approval`)

| Policy | Semantics |
|---|---|
| `never` | Never asks; failures return straight to the model. **Default for `exec`** — nothing can block a headless run. |
| `on-request` | Model decides when to ask. Preferred for interactive runs. |
| `untrusted` | Only trusted commands (ls, cat, sed…) run without asking. |
| `on-failure` | Deprecated — asks only to escalate a failed command out of the sandbox. |

## `codex exec` flags

| Flag | Meaning |
|---|---|
| `[PROMPT]` / `-` | Brief as argument, or read from stdin; piped stdin is appended as a `<stdin>` block |
| `-C, --cd <dir>` | Working root for the agent |
| `-s, --sandbox <mode>` | See sandbox modes |
| `-o, --output-last-message <file>` | Write the final agent message to a file |
| `--output-schema <file>` | JSON Schema the final response must match |
| `--json` | Emit events as JSONL on stdout |
| `-i, --image <file>...` | Attach images to the prompt |
| `-m, --model <model>` | Override model |
| `-c, --config key=value` | Override any config.toml key (dotted path, TOML value) |
| `-p, --profile <name>` | Layer `$CODEX_HOME/<name>.config.toml` over base config |
| `--add-dir <dir>` | Extra writable roots |
| `--search` | Enable native web_search tool |
| `--skip-git-repo-check` | Allow running outside a git repo |
| `--ephemeral` | Don't persist session files |
| `--ignore-user-config` / `--ignore-rules` | Skip config.toml / execpolicy `.rules` loading |
| `--oss`, `--local-provider <lmstudio\|ollama>` | Use a local open-source model |
| `--enable/--disable <feature>` | Toggle feature flags |
| `--color <always\|never\|auto>` | Output color |

`codex exec resume` accepts the same steering flags plus `[SESSION_ID]` (UUID or thread name), `--last`, and `--all` (disable cwd filtering).

## `codex review` flags

| Flag | Meaning |
|---|---|
| `[PROMPT]` | Custom review instructions (`-` reads stdin) |
| `--uncommitted` | Review staged + unstaged + untracked changes |
| `--base <branch>` | Review against a base branch |
| `--commit <sha>` | Review a single commit |
| `--title <title>` | Title shown in the review summary |

## Useful `-c` config overrides

| Key | Effect |
|---|---|
| `model_reasoning_effort` | `minimal`/`low`/`medium`/`high`/`xhigh` — this machine defaults to `xhigh` |
| `sandbox_workspace_write.network_access=true` | Network inside workspace-write sandbox |
| `shell_environment_policy.inherit=all` | Pass the full environment to spawned commands |
| `features.<name>=true` | Same as `--enable <name>` |

## This machine's config highlights (`configs/codex/config.toml` → `~/.codex/config.toml`)

- `model = "gpt-5.5"`, `model_reasoning_effort = "xhigh"`, `service_tier = "default"`
- MCP server `fff` (grep/multi_grep/find_files) pre-approved — Codex has fast code search
- Plugins enabled: github, browser, computer-use, figma, posthog, documents/spreadsheets/presentations, pdf
- Most local repos are `trust_level = "trusted"` under `[projects]`
- `notify` hook pings the Codex desktop app on turn end

## Output anatomy of a headless run

```
OpenAI Codex v0.142.4
--------
workdir: …          model: gpt-5.5       provider: openai
approval: never     sandbox: read-only   reasoning effort: xhigh
session id: 019f216d-0724-72b1-…         ← capture for resume
--------
user …              (echo of the brief)
codex …             (final message — also written via -o)
tokens used …
```

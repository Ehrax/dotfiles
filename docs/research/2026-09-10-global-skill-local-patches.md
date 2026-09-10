# Local global-skill corrections, 2026-09-10

The user requested concrete, reversible corrections from the Codex collaboration audit. These changes build on the existing dirty working files, not Git HEAD. The initial application made no commit, registry change or upstream update. The user subsequently requested committing and pushing the audit changes. The commit applies that scoped delta to the tracked versions; older unrelated edits remain in the working tree, including the prior TUI-to-HTML prototype conversion.

Local sources patched: `configs/agents/GLOBAL_AGENTS.md`, plus `diagnosing-bugs/SKILL.md`, `prototype/{SKILL,UI,LOGIC}.md`, `research/SKILL.md` and `code-review/SKILL.md` under `configs/agents/skills`.

The four skill packages have installation records from `mattpocock/skills` in `~/.agents/.skill-lock.json` (last recorded update 2026-08-28). Their existing local modifications and that registry were preserved. These are disclosed local adaptations, not an upstream package release. A skills updater may replace them: review the local delta before updating and reapply only still-relevant corrections. Do not change registry hashes to pretend they are upstream content.

Changes: symptom-specific UI reproduction and proportional diagnosis; one to three purposeful prototype options with preservation of selected composition; optional branch/issue archival; direct research and review without mandatory delegation or tracker setup; correct handling of uncommitted review scope. Global collaboration guidance records scope, shared-resource ownership, and the distinction between implementation, actual verification and user acceptance.

The full inventory, the incremental patch against the pre-task working files, byte-preserving backup and guarded rollback are in the projectless task's outputs:

`/Users/ehrax/Documents/Codex/2026-09-10/wir-setzen-das-audit-unserer-codex/outputs/`

- `skill-audit-changes.patch`
- `skill-audit-backup/`
- `skill-audit-manifest.json`
- `rollback-skill-audit.py` (preview by default; restore only after checking current hashes)
- `2026-09-10-global-skill-audit-result.md`

Validation: all four changed skill entrypoints pass the bundled quick validator. Scenario review is a local reasoning check, not an independent model experiment or proof of future production behavior. QVR/Expo skills, plugin caches, invocation policies and memories were outside this patch.

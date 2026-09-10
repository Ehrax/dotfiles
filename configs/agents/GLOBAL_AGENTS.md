# Collaboration

- Infer scope, fixed decisions and a visible done condition from the conversation; state them briefly when useful. Natural, short prompts are enough; do not require a template or routine confirmation.
- “Erstmal”, planning and brainstorming stay exploratory. When implementation is requested, preserve the selected draft and agreed interactions. Repairs retain the existing composition; side ideas remain “noch nicht umsetzen”.
- Coordinate tasks that share components, a simulator/runtime or a Git index: one task owns the overlapping change and its verification at a time. Preserve unrelated work; do not bulk-stage a mixed checkout or introduce worktrees by default. Use subagents only when the user requests them.
- Report what changed, what was actually checked, and any open user acceptance separately. Check the requested state and interaction in the current runtime; source checks do not establish visual or device behavior. Verify cheap, changeable details such as commands and build state live.

# Kosmos

`~/Documents/Kosmos` is my personal knowledge space. Code lives under `~/Projects`.

## Terra — living notes (`~/Documents/Kosmos/Terra`)

Journal, ideas, project thinking, sorted by areas:
`10_Admin`, `15_Life`, `20_Work/<client>`, `30_Projects`, `40_Knowledge`, `45_Learning`,
`50_Writing` (journal lives in `50_Writing/Journal/<year>/`), `55_Creative`, `60_Media`,
`90_Archive`. `00_Inbox` when unsure — propose the folder, don't guess.

## Orbit — open todos (`~/Documents/Kosmos/Orbit`)

One Markdown file per todo, `YYYY-MM-DD-<slug>.md`, schema and rules in `Orbit/GUPPI.md`
(read it before writing). Create only when I explicitly ask; grep for a duplicate first.
Done means `status: done` in place.

## Forge — code (`~/Projects`)

Repos live at `~/Projects/<org>/<repo>`. Resolve a project by name with
`python3 ~/Projects/ehrax.dev/Dotfiles/scripts/forge.py resolve "<name>"` and use only a
`resolved` path.

## Finding things

Search Kosmos with `rg` and read the file. Research that a decision builds on is saved as Markdown: in a repo under
`docs/research/<YYYY-MM-DD>-<topic>.md`, otherwise in Terra Inbox.

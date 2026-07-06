# Model table — canonical pattern

Paste-source for the "Picking models for delegated work" block in every project's AGENTS.md.
Not symlinked by design: each project may tweak it. When the roster changes (new model,
pricing shift), update HERE first, then sweep the projects.

<!-- BLOCK START — copy from here -->
## Picking models for delegated work

Rankings, higher = better. Cost reflects real subscription pressure, not list price.
Intelligence = how hard a problem the model handles unsupervised. Taste = UI/UX, code
quality, API design, copy.

| model     | cost | intelligence | taste |
|-----------|------|--------------|-------|
| gpt-5.5   | 7    | 8            | 5     |
| opus-4.8  | 4    | 7            | 8     |
| sonnet-5  | 6    | 5            | 7     |

- Defaults, not limits: if a cheaper model's output misses the bar, redo with a smarter one without asking. Judge the output, not the price tag.
- When axes conflict for anything that ships: intelligence > taste > cost.
- Bulk/mechanical with a tight brief (clear-spec implementation, migrations, commit/push sweeps): gpt-5.5. Never pick haiku on your own — the user invokes it explicitly when wanted.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7: opus-4.8, sonnet-5 as budget option.
- Default driver split: gpt-5.5 drives backend and logic work (services, data, glue — including logic inside frontend code); Claude drives frontend/visual work.
- Reviews of plans/implementations: opus-4.8, plus gpt-5.5 as an independent second perspective.
- Also on the codex account (via `codex -m`): gpt-5.4, gpt-5.4-mini, gpt-5.3-codex-spark (very fast execution) — the user invokes these explicitly; don't auto-pick them.
- Mechanics: gpt-5.5 only via the codex CLI (`codex exec` / `codex review`); Claude models via the Agent/Workflow `model` parameter. Full delegation playbook: the `orchestrate` skill.
<!-- BLOCK END -->

# Model routing

Scores are directional defaults, not benchmarks. Higher is better. Cost means lower
real subscription pressure, not lower API list price. Intelligence = how hard a problem
the model handles unsupervised. Taste = UI/UX, code quality, API design, and copy. New
model scores are provisional until repeated project work gives better evidence.

| model           | cost | intelligence | taste |
|-----------------|------|--------------|-------|
| gpt-5.6-sol     | 5    | 10           | 8     |
| fable-5         | 2    | 9            | 9     |
| gpt-5.6-terra   | 8    | 8            | 7     |
| gpt-5.6-luna    | 10   | 6            | 6     |
| opus-4.8        | 4    | 7            | 8     |
| sonnet-5        | 6    | 5            | 7     |

- Defaults are not limits. If a cheaper model misses the bar, redo with a stronger one. Judge the output, not the price tag.
- When axes conflict for anything that ships: intelligence > taste > cost.
- Tight, mechanical work: gpt-5.6-luna. Escalate to Terra if the task stops being mechanical.
- Backend, services, data, glue, and frontend logic: gpt-5.6-terra.
- Hard unsupervised work, architecture, difficult debugging, and final high-stakes review: gpt-5.6-sol.
- User-facing UI, copy, and API design require taste ≥ 7: fable-5 when quality matters most; opus-4.8 by default; Sol when maximum reasoning is also required; Terra or sonnet-5 as budget options.
- Reviews: gpt-5.6-sol, with fable-5 or opus-4.8 as the independent taste-and-design perspective.
- Also available through `codex -m`: gpt-5.5, gpt-5.4, gpt-5.4-mini, and gpt-5.3-codex-spark. Use these only when explicitly requested.
- GPT models run through the Codex CLI (`codex exec` / `codex review`); Claude models run through the Agent/Workflow `model` parameter. Use the `orchestrate` skill for the full delegation playbook.

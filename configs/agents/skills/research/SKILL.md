---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it as a Markdown file — a bare link is not a record:
   - Inside a code repo (`~/Projects/...`): `<repo>/docs/research/<YYYY-MM-DD>-<topic>.md`.
   - Everything else belongs in Terra (`~/Documents/Kosmos/Terra`). Do not guess the folder:
     propose a path ("I'd file this under `Terra/45_Learning/Chess/…` — ok?") and wait for the yes.
   - Never create a new folder at a repo root (`./research`) or next to `~/Documents/Kosmos`.

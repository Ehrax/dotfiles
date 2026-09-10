---
name: research
description: Investigate a substantive question against primary sources and save decision-relevant findings as Markdown. Use for requested research or an unresolved technical choice that needs a durable source record; a routine fact lookup does not need this workflow.
---

Do the research directly. Delegate a bounded part only when the user has requested delegation and useful independent work remains; this skill does not grant that permission.

Research process:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it as a Markdown file — a bare link is not a record:
   - Inside a code repo (`~/Projects/...`): `<repo>/docs/research/<YYYY-MM-DD>-<topic>.md`.
   - For project-independent research, follow the global Terra Inbox convention; propose the folder if not already agreed. Honor a user-specified destination and existing approval instead of asking again. Prepare the complete local draft while an unresolved filing choice is pending.
   - Never create a new folder at a repo root (`./research`) or next to `~/Documents/Kosmos`.

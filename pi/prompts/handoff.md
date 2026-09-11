---
description: Compact this conversation into a handoff document for a fresh agent session
argument-hint: "[what the next session will focus on]"
---
Read `/Users/evan.zeller/.agents/skills/handoff/SKILL.md` and follow it exactly.

That skill is marked `disable-model-invocation: true`, so it is never loaded automatically — read it with the `read` tool before doing anything else, and treat its instructions as authoritative over your own defaults (in particular: write the document to the OS temp directory, **not** the workspace; include a "suggested skills" section; reference existing artifacts by path instead of restating them; redact secrets and PII).

Next session's focus: ${ARGUMENTS:-not specified — infer it from the conversation and say so explicitly in the document}

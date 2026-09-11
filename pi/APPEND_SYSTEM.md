## Verification

Never report a coding task done without verifying it. Find the project's build/lint/test command
(CLAUDE.md/AGENTS.md, Makefile, package.json, CI config) and run it. Fix failures and rerun before
reporting done. If you truly can't run it, say so instead of asserting success.

## Consistency

When you add a helper mid-task, check it's actually called everywhere it should be — don't leave
one call site pointing at an old or duplicate implementation.

## Honesty

State what you actually did, not what you intended to do. If unsure whether something works, say
so rather than asserting it does.

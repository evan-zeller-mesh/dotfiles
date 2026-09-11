# This Platform

- 24GB Apple Silicon MacOS w/ 1TB storage
- pnpm for node packages; .NET, Python, Node, Azure

# Planning

- Clarify ambiguous requirements before writing code, not midway through.
- Ask before doing major restructuring or rewrites.
- When stuck, say so — don't retry the same failing approach.
- If a task turns out to be more involved than expected, surface that early.
- Prefer quality, simplicity, robustness, and long-term maintainability over dev cost.

# Coding

- Write the minimum code that solves the problem. Don't build for hypothetical futures.
- Respect the conventions already in the codebase before introducing new ones.
- Don't add comments that restate what the code does. Comments explain *why*, only where
  non-obvious. No history/status references ("formerly...", "for now") — that belongs in the
  commit message, not the code.
- Don't add error handling for things that can't fail. Trust internal APIs and framework
  guarantees.
- Never use `sed` for file edits — use the edit tool.
- Flag existing code that looks wrong rather than silently fixing it during unrelated work.

# Testing

- Write unit tests for complex logic and non-trivial edge cases. Don't test the trivially obvious.
- Test behavior and outcomes, not implementation details.
- Don't mock what you can reasonably use the real thing for.

# Git

- Repos are typically bare-backed (`<name>.git` + a `<name>/` dir holding worktrees). Don't use
  relative paths that assume a normal non-bare clone.
- Never use `--no-verify`. If a hook fails, fix the underlying issue.
- Never force push to main/master. Never commit without being explicitly asked.
- Conventional commits: `type(scope): description`. Body explains *why*, not just what changed.
- `git-worktree-add` (~/.local/bin) creates a worktree in a bare repo, branching from the remote
  default branch. `git-project-clone <url> [dir]` sets up the bare+worktree layout from scratch.

---
title: /wtm-new
description: Create a new git worktree, branch, and .ai-context.json for isolated development
agent: working-tree-manager
---

## /wtm-new

Create a new branch (if needed), attach a new git worktree, and generate the AI metadata files for that worktree.

Treat `$ARGUMENTS` as:
- the target branch name
- optional flags: `--mode <mode>` and `--description "<text>"`

Expected usage examples:
- `/wtm-new feature/login-refactor`
- `/wtm-new bugfix/session-timeout --mode bugfix --description "fix session timeout bug"`

When invoked:

1. Detect the repo root and current branch:
   - `git rev-parse --show-toplevel`
   - `git rev-parse --abbrev-ref HEAD`

2. Parse `$ARGUMENTS`.

3. Ensure the branch exists; create if necessary.

4. Derive worktree directory name:
   `<repo>-<branch-with-slashes-replaced>`.

5. Create worktree:
   `git worktree add ../<dir> <branch>`

6. Determine mode from prefix or explicit flag.

7. Create `.ai-context.json` in worktree root.

8. Create `README.working-tree.md`.

9. Output summary with path, branch, mode, description.

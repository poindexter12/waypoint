---
title: /wtm-destroy
description: Safely remove a git worktree and its metadata (but not the underlying branch)
agent: working-tree-manager
---

## /wtm-destroy

Destroy a worktree directory and remove metadata.

Steps:
1. Parse `$ARGUMENTS` as the worktree path.

2. Validate it is a registered worktree.

3. Remove via `git worktree remove --force <path>`.

4. Remove metadata files if still present:
   - `.ai-context.json`
   - `README.working-tree.md`

5. Do not delete the branch; advise on branch deletion if asked.

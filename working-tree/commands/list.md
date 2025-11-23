---
title: /wtm-list
description: List all git worktrees with their associated .ai-context metadata
agent: working-tree-manager
---

## /wtm-list

Enumerate all git worktrees and annotate each with metadata if present.

Steps:
1. Run `git worktree list --porcelain`.

2. For each worktree, inspect `.ai-context.json`.

3. Output:
   - path
   - branch
   - mode or "unknown"
   - description if available.

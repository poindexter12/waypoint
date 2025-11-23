---
title: /wtm-status
description: Show metadata for the current git worktree from .ai-context.json
agent: working-tree-manager
---

## /wtm-status

Show the current worktree’s AI context and git information.

Steps:
1. Detect repo root via `git rev-parse --show-toplevel`.

2. Detect branch via `git rev-parse --abbrev-ref HEAD`.

3. Load `.ai-context.json`.

4. Display:
   - worktree
   - branch
   - mode
   - description
   - created timestamp

5. If metadata missing, suggest `/wtm-adopt`.

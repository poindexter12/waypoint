---
title: /wtm-adopt
description: Generate .ai-context.json for an existing worktree lacking metadata
agent: working-tree-manager
---

## /wtm-adopt

Adopt an existing worktree and attach metadata.

Steps:
1. Detect repo root and branch.

2. Determine directory name.

3. If metadata already exists, notify user.

4. Create `.ai-context.json` with inferred or provided mode and description.

5. Create `README.working-tree.md` if missing.

6. Output confirmation with metadata.

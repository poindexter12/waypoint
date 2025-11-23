---
description: Show metadata for the current git worktree from .ai-context.json
allowed-tools: Bash, Read
model: sonnet
---

# /wtm-status - Show Worktree Metadata

Display the current worktree's AI context metadata and git information.

## Arguments

None. Operates on the current directory.

## Usage

```bash
/wtm-status
```

## Behavior

### Step 1: Detect Repository Root
```bash
git rev-parse --show-toplevel
```

If this fails:
- Not in a git repository
- Show error and exit

### Step 2: Detect Current Branch
```bash
git rev-parse --abbrev-ref HEAD
```

### Step 3: Check for .ai-context.json
Look for file at `<repo-root>/.ai-context.json`

### Step 4a: If Metadata Exists - Display Full Status

```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    <worktree-name>
Branch:       <branch-name>
Mode:         <mode>
Created:      <created-timestamp>

Purpose:
<description or "No description provided">

───────────────────────────────────────────────────────────

Mode Semantics:
  main       → Minimal changes, stable work only
  feature    → Active development, larger changes allowed
  bugfix     → Isolated, surgical fixes only
  experiment → Prototypes, large swings, unsafe changes allowed
  review     → Documentation, analysis, audits

Metadata file: .ai-context.json
```

### Step 4b: If Metadata Missing - Suggest Adoption

```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    <repo-name>
Branch:       <branch-name>
Mode:         (no metadata)

⚠ No .ai-context.json found

This worktree doesn't have AI context metadata.

To add metadata to this worktree:
  /wtm-adopt [--mode <mode>] [--description "<text>"]

To create a new worktree with metadata:
  /wtm-new <branch-name>
```

## Output Examples

### Example 1: Worktree with Metadata

```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    myapp-feature-login
Branch:       feature/login-refactor
Mode:         feature
Created:      2025-11-23T10:30:00Z

Purpose:
Refactor authentication flow to support OAuth2

───────────────────────────────────────────────────────────

Mode Semantics:
  main       → Minimal changes, stable work only
  feature    → Active development, larger changes allowed
  bugfix     → Isolated, surgical fixes only
  experiment → Prototypes, large swings, unsafe changes allowed
  review     → Documentation, analysis, audits

Metadata file: .ai-context.json
```

### Example 2: No Metadata

```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    myapp
Branch:       main
Mode:         (no metadata)

⚠ No .ai-context.json found

This worktree doesn't have AI context metadata.

To add metadata to this worktree:
  /wtm-adopt [--mode <mode>] [--description "<text>"]

To create a new worktree with metadata:
  /wtm-new <branch-name>
```

## Error Handling

### Not in Git Repository
```
Error: Not in a git repository

Run this command from within a git repository.
```

### Git Command Failed
```
Error: Failed to read git information

Git error: <error message>

Check that:
  - You're in a git repository
  - Git is installed and working
```

### Invalid JSON in .ai-context.json
```
Warning: .ai-context.json exists but is invalid

JSON error: <error message>

The metadata file may be corrupted. Consider:
  - Fixing the JSON manually
  - Running /wtm-adopt to regenerate
```

## Implementation Notes

- Always read `.ai-context.json` from repository root (detected via `git rev-parse --show-toplevel`)
- Handle missing file gracefully (not an error, just no metadata)
- Parse JSON carefully and handle parse errors
- Display timestamps in readable format (keep ISO format or convert to local time)
- Use box-drawing characters for visual clarity (optional, can use simple text)

## Related

- `/wtm-adopt` - Add metadata to current worktree
- `/wtm-new` - Create new worktree with metadata
- `/wtm-list` - List all worktrees
- For understanding your worktree organization, invoke the `working-tree-consultant` agent

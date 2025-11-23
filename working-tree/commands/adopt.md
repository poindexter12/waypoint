---
description: Add .ai-context.json metadata to an existing worktree
argument-hint: [--mode <mode>] [--description "<text>"]
allowed-tools: Bash, Write, Read
model: sonnet
---

# /wtm-adopt - Add Metadata to Existing Worktree

Generate `.ai-context.json` and `README.working-tree.md` for an existing worktree that lacks metadata.

## Arguments

- `--mode <mode>` (optional): Worktree mode (main|feature|bugfix|experiment|review)
  - If omitted, inferred from branch name
  - Default: `feature`
- `--description "<text>"` (optional): Freeform description of worktree purpose
  - Default: Empty string

## Usage

```bash
/wtm-adopt
/wtm-adopt --mode feature --description "Working on new API"
/wtm-adopt --description "Fixing critical bug"
```

## Behavior

### Step 1: Detect Repository Info
```bash
git rev-parse --show-toplevel  # Get repo root
git rev-parse --abbrev-ref HEAD  # Get current branch
```

Extract directory name from repo root path.

### Step 2: Check for Existing Metadata

Check if `.ai-context.json` already exists at repo root.

- **If exists**: Display current metadata and ask if user wants to overwrite
- **If not exists**: Proceed with creation

### Step 3: Infer Mode from Branch Name (if not specified)

Same logic as `/wtm-new`:
- Branch starts with `feature/` → mode: `feature`
- Branch starts with `bugfix/` or `fix/` → mode: `bugfix`
- Branch starts with `exp/` or `experiment/` → mode: `experiment`
- Branch starts with `review/` → mode: `review`
- Branch is `main` or `master` → mode: `main`
- Default → mode: `feature`

### Step 4: Determine Worktree Directory Name

Extract from current path:
```bash
basename $(git rev-parse --show-toplevel)
```

### Step 5: Generate .ai-context.json

Create file at `<repo-root>/.ai-context.json`:

```json
{
  "worktree": "<worktree-dir-name>",
  "branch": "<branch-name>",
  "mode": "<mode>",
  "created": "<ISO 8601 UTC timestamp>",
  "description": "<description>"
}
```

Timestamp: Current time in UTC, ISO 8601 format (`2025-11-23T12:34:56Z`)

### Step 6: Generate README.working-tree.md (if missing)

Create file at `<repo-root>/README.working-tree.md`:

```markdown
# Worktree: <worktree-dir-name>

**Branch:** `<branch-name>`
**Mode:** `<mode>`
**Created:** <ISO 8601 timestamp>

## Purpose

<description or "No description provided">

## Mode Semantics

- **main**: Minimal changes, stable work only
- **feature**: Active development, larger changes allowed
- **bugfix**: Isolated, surgical fixes only
- **experiment**: Prototypes, large swings, unsafe changes allowed
- **review**: Documentation, analysis, audits

## About This Worktree

This directory is an independent Git worktree attached to the main repository.

- Main repo: <path-to-main-repo-if-applicable>
- Worktree path: <absolute-path-to-this-worktree>
- Branch: `<branch-name>`

See `.ai-context.json` for machine-readable metadata.
```

### Step 7: Output Confirmation

```
Adopted worktree successfully!

  Directory: <worktree-dir-name>
  Branch: <branch-name>
  Mode: <mode>
  Description: <description or "None">

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md (created/updated)

Use /wtm-status to view metadata anytime.
```

## Output Examples

### Example 1: Fresh Adoption

```
Adopting current worktree...

Directory:    myapp-feature-login
Branch:       feature/login-refactor
Mode:         feature (inferred from branch name)
Description:  None provided

Creating metadata files...

✓ Adopted worktree successfully!

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md

Use /wtm-status to view metadata anytime.
```

### Example 2: With Explicit Mode and Description

```
Adopting current worktree...

Directory:    myapp
Branch:       main
Mode:         main (explicitly set)
Description:  Primary development branch

Creating metadata files...

✓ Adopted worktree successfully!

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md

Use /wtm-status to view metadata anytime.
```

### Example 3: Metadata Already Exists

```
Current worktree already has metadata:

  Directory:    myapp-feature-login
  Branch:       feature/login-refactor
  Mode:         feature
  Created:      2025-11-23T10:30:00Z
  Description:  OAuth2 authentication refactor

Do you want to overwrite this metadata?
[Requires user confirmation]

Options:
  1. Keep existing metadata (recommended)
  2. Overwrite with new metadata
  3. Cancel

If user chooses overwrite:
  ✓ Metadata updated successfully!
```

## Error Handling

### Not in Git Repository
```
Error: Not in a git repository

Run this command from within a git repository.

To create a new worktree with metadata:
  /wtm-new <branch-name>
```

### Invalid Mode
```
Error: Invalid mode '<mode>'

Valid modes: main, feature, bugfix, experiment, review

Example:
  /wtm-adopt --mode feature --description "new feature work"
```

### File Write Error
```
Error: Failed to write metadata files

Reason: <error message>

Check that:
  - You have write permission in this directory
  - Disk space is available
  - No file conflicts exist
```

### Git Command Failed
```
Error: Failed to read git information

Git error: <error message>

Check that:
  - You're in a git repository
  - Git is installed and working
```

## Use Cases

### Adopting Main Repository

When working in the main repo without worktrees:
```bash
cd ~/myapp
/wtm-adopt --mode main --description "Primary development branch"
```

### Adopting Existing Worktree

If you created a worktree manually without `/wtm-new`:
```bash
cd ../myapp-feature-something
/wtm-adopt
```

### Adding Description Later

If you created worktree without description:
```bash
/wtm-adopt --description "Working on user authentication refactor"
```
(Will prompt to overwrite existing metadata)

### Correcting Mode

If mode was inferred incorrectly:
```bash
/wtm-adopt --mode experiment
```
(Will prompt to overwrite existing metadata)

## Implementation Notes

- Always operate on current directory (from `git rev-parse --show-toplevel`)
- Always check for existing `.ai-context.json` before creating
- If metadata exists, ask user before overwriting
- Generate timestamp at time of adoption, not creation
- Infer mode from branch name if not explicitly provided
- Create `README.working-tree.md` only if it doesn't exist
- Handle both worktrees and main repository
- Use absolute paths in README for clarity

## Related

- `/wtm-status` - View current metadata after adoption
- `/wtm-new` - Create new worktree with metadata from start
- `/wtm-list` - See all worktrees and their metadata status
- For organizing your worktree adoption strategy, invoke the `working-tree-consultant` agent

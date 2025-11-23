---
description: Create a new git worktree with branch and .ai-context.json metadata
argument-hint: <branch-name> [--mode <mode>] [--description "<text>"]
allowed-tools: Bash, Write, Read
model: sonnet
---

# /wtm-new - Create Git Worktree

Create a new branch (if needed), attach a new git worktree, and generate AI metadata files for isolated development.

## Arguments

- `<branch-name>` (required): Name of the branch to create or checkout
- `--mode <mode>` (optional): Worktree mode (main|feature|bugfix|experiment|review)
  - If omitted, inferred from branch prefix (feature/, bugfix/, exp/, etc.)
  - Default: `feature`
- `--description "<text>"` (optional): Freeform description of worktree purpose
  - Default: Empty string

## Usage Examples

```bash
/wtm-new feature/login-refactor
/wtm-new bugfix/session-timeout --mode bugfix --description "fix session timeout bug"
/wtm-new exp/ai-spike --mode experiment --description "prototype AI integration"
/wtm-new main --mode main
```

## Behavior

### Step 1: Detect Repository Info
```bash
git rev-parse --show-toplevel  # Get repo root
git rev-parse --abbrev-ref HEAD  # Get current branch
```

### Step 2: Parse Arguments
- Extract branch name (required first argument)
- Parse optional `--mode` flag
- Parse optional `--description` flag
- Validate mode is one of: main, feature, bugfix, experiment, review

### Step 3: Infer Mode from Branch Name (if not specified)
- Branch starts with `feature/` → mode: `feature`
- Branch starts with `bugfix/` or `fix/` → mode: `bugfix`
- Branch starts with `exp/` or `experiment/` → mode: `experiment`
- Branch starts with `review/` → mode: `review`
- Branch is `main` or `master` → mode: `main`
- Default → mode: `feature`

### Step 4: Check if Branch Exists
```bash
git show-ref --verify --quiet refs/heads/<branch-name>
```
- If exists: Use existing branch
- If not exists: Create from current HEAD
  ```bash
  git branch <branch-name>
  ```

### Step 5: Derive Worktree Directory Name
Pattern: `<repo-name>-<branch-name-normalized>`

Normalization:
- Replace `/` with `-`
- Replace `_` with `-`
- Lowercase

Examples:
- `myapp` + `feature/login` → `myapp-feature-login`
- `api-server` + `bugfix/session` → `api-server-bugfix-session`

### Step 6: Check Worktree Doesn't Already Exist
```bash
git worktree list --porcelain | grep "branch refs/heads/<branch-name>"
```
- If found: Error and exit ("Branch <branch-name> already has a worktree at <path>")

### Step 7: Create Worktree
```bash
git worktree add ../<worktree-dir> <branch-name>
```

Place worktree in parent directory (sibling to current repo).

### Step 8: Generate .ai-context.json
Create file at `../<worktree-dir>/.ai-context.json`:

```json
{
  "worktree": "<worktree-dir>",
  "branch": "<branch-name>",
  "mode": "<mode>",
  "created": "<ISO 8601 UTC timestamp>",
  "description": "<description>"
}
```

Timestamp format: `2025-11-23T12:34:56Z`

### Step 9: Generate README.working-tree.md
Create file at `../<worktree-dir>/README.working-tree.md`:

```markdown
# Worktree: <worktree-dir>

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

- Main repo: `<path-to-main-repo>`
- Worktree path: `<absolute-path-to-worktree>`
- Branch: `<branch-name>`

See `.ai-context.json` for machine-readable metadata.
```

### Step 10: Output Summary

```
Created worktree successfully!

  Path: ../<worktree-dir>
  Branch: <branch-name>
  Mode: <mode>
  Description: <description or "None">

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md

To switch to this worktree:
  cd ../<worktree-dir>
```

## Error Handling

### Branch Already Has Worktree
```
Error: Branch '<branch-name>' already has a worktree at <path>

Use one of:
  - /wtm-list to see all worktrees
  - cd <path> to use the existing worktree
  - /wtm-destroy <path> to remove it first
```

### Invalid Mode
```
Error: Invalid mode '<mode>'

Valid modes: main, feature, bugfix, experiment, review

Example:
  /wtm-new my-branch --mode feature
```

### Git Command Failed
```
Error: Failed to create worktree

Git error: <error message>

Check that:
  - You're in a git repository
  - Branch name is valid
  - You have permission to create directories
```

### Directory Already Exists
```
Error: Directory '../<worktree-dir>' already exists

Choose a different branch name or remove the existing directory.
```

## Implementation Notes

- Always create worktree in parent directory (`../<name>`)
- Always use absolute paths in README
- Always validate mode before creating files
- Always generate timestamp in UTC
- Never delete or modify existing branches
- Never overwrite existing worktrees

## Related

- `/wtm-status` - Show current worktree metadata
- `/wtm-list` - List all worktrees
- `/wtm-adopt` - Add metadata to existing worktree
- `/wtm-destroy` - Remove worktree safely
- For complex worktree strategies, invoke the `working-tree-consultant` agent

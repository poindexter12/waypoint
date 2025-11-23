---
description: Safely remove a git worktree and its metadata (preserves branch)
argument-hint: <worktree-path>
allowed-tools: Bash, Read
model: sonnet
---

# /wtm-destroy - Remove Git Worktree

Safely remove a git worktree directory and its metadata files. The underlying branch is preserved.

## Arguments

- `<worktree-path>` (required): Path to the worktree to remove
  - Can be absolute: `/Users/joe/myapp-feature-login`
  - Can be relative: `../myapp-feature-login`

## Usage

```bash
/wtm-destroy ../myapp-feature-login
/wtm-destroy /absolute/path/to/worktree
```

## Behavior

### Step 1: Validate Worktree Path

Check if path is a registered git worktree:
```bash
git worktree list --porcelain
```

Parse output and verify the provided path matches a registered worktree.

### Step 2: Safety Checks

Before removal, verify:
1. Path exists and is a directory
2. Path is a git worktree (not just any directory)
3. Path is not the main repository (prevent accidental main repo deletion)

### Step 3: Check for Uncommitted Changes

```bash
cd <worktree-path>
git status --porcelain
```

If uncommitted changes exist:
- **Warn user** but allow removal with `--force` flag
- Show what changes will be lost
- Require confirmation

### Step 4: Remove Worktree

```bash
git worktree remove --force <worktree-path>
```

Use `--force` to remove even with uncommitted changes (after user confirmation).

### Step 5: Clean Up Stale References

```bash
git worktree prune
```

Remove any stale worktree administrative files.

### Step 6: Confirm Branch Preservation

Display message:
```
Worktree removed: <worktree-path>

Branch '<branch-name>' has been preserved.

To delete the branch as well:
  git branch -d <branch-name>   # Safe delete (only if merged)
  git branch -D <branch-name>   # Force delete (even if unmerged)
```

## Output Examples

### Example 1: Clean Removal

```
Removing worktree: /Users/joe/myapp-feature-login

Checking for uncommitted changes... None found.
Removing worktree directory... Done.
Pruning stale references... Done.

✓ Worktree removed successfully

Branch 'feature/login-refactor' has been preserved.

To delete the branch:
  git branch -d feature/login-refactor
```

### Example 2: Uncommitted Changes Warning

```
Removing worktree: /Users/joe/myapp-bugfix-auth

⚠ Warning: Uncommitted changes detected

Modified files:
  M src/auth.ts
  M tests/auth.test.ts

?? new-file.ts

These changes will be lost if you proceed.

Recommendations:
  1. Commit changes: cd /Users/joe/myapp-bugfix-auth && git commit -am "message"
  2. Stash changes: cd /Users/joe/myapp-bugfix-auth && git stash
  3. Proceed anyway (changes will be lost)

Proceed with removal? (This will permanently delete uncommitted work)
[Requires user confirmation via AskUserQuestion or similar]

If confirmed:
  Removing worktree... Done.
  ✓ Worktree removed (uncommitted changes were discarded)
```

### Example 3: Main Repository Protection

```
Error: Cannot destroy main repository

The path '/Users/joe/myapp' is the main repository, not a worktree.

To remove worktrees, use paths like:
  /wtm-destroy ../myapp-feature-branch
  /wtm-destroy ../myapp-bugfix-something

To see all worktrees:
  /wtm-list
```

## Error Handling

### Path Not a Worktree
```
Error: Not a registered git worktree

Path: <provided-path>

This path is not a git worktree. To see all worktrees:
  /wtm-list

Valid worktree paths look like:
  /Users/joe/myapp-feature-login
  ../myapp-bugfix-auth
```

### Path Doesn't Exist
```
Error: Path does not exist

Path: <provided-path>

The specified path doesn't exist. Check for typos.

To list existing worktrees:
  /wtm-list
```

### No Path Provided
```
Error: Missing worktree path

Usage:
  /wtm-destroy <worktree-path>

Example:
  /wtm-destroy ../myapp-feature-login

To see all worktrees:
  /wtm-list
```

### Git Command Failed
```
Error: Failed to remove worktree

Git error: <error message>

This can happen if:
  - Worktree is locked
  - Permission issues
  - Worktree is corrupted

Try:
  - Check file permissions
  - Run: git worktree prune
  - Manually remove directory and run: git worktree prune
```

## Safety Features

### Protected Operations
- Cannot remove main repository
- Warns about uncommitted changes
- Requires confirmation for destructive operations
- Preserves branch by default

### Branch Deletion Guidance

After removal, if user wants to delete the branch too:

**Safe delete** (only if merged):
```bash
git branch -d <branch-name>
```

**Force delete** (even if unmerged):
```bash
git branch -D <branch-name>
```

**Remote branch delete**:
```bash
git push origin --delete <branch-name>
```

## Implementation Notes

- Always validate path is a worktree using `git worktree list`
- Always check for uncommitted changes before removal
- Never delete the main repository (check if path matches main worktree)
- Always run `git worktree prune` after removal
- Display clear confirmation messages
- Provide guidance on branch deletion (but never auto-delete branches)
- Handle both absolute and relative paths
- Resolve relative paths to absolute before validation

## Related

- `/wtm-list` - See all worktrees before deciding what to remove
- `/wtm-status` - Check current worktree before removing
- `/wtm-new` - Create new worktree after removal
- For guidance on when to remove worktrees, invoke the `working-tree-consultant` agent

---
description: List all git worktrees with their associated .ai-context metadata
allowed-tools: Bash, Read, Glob
model: sonnet
---

# /wtm-list - List All Worktrees

Enumerate all git worktrees and display their metadata from `.ai-context.json`.

## Arguments

None.

## Usage

```bash
/wtm-list
```

## Behavior

### Step 1: Get All Worktrees
```bash
git worktree list --porcelain
```

Parse output format:
```
worktree /path/to/worktree
HEAD <commit-hash>
branch refs/heads/<branch-name>

worktree /another/path
HEAD <commit-hash>
branch refs/heads/<another-branch>
```

### Step 2: For Each Worktree, Read Metadata

For each worktree path:
1. Check for `.ai-context.json` at `<worktree-path>/.ai-context.json`
2. If exists: Parse and extract mode, description, created
3. If not exists: Mark as "no metadata"

### Step 3: Display Summary Table

```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
/path/to/main                 main                main         Production repo
/path/to/myapp-feature-login  feature/login       feature      OAuth2 refactor
/path/to/myapp-bugfix-auth    bugfix/auth-fix     bugfix       Session timeout
/path/to/myapp-exp-ai         exp/ai-integration  experiment   AI spike
/path/to/old-worktree         feature/old         (no metadata) -

═══════════════════════════════════════════════════════════════════════════════
Total: 5 worktrees (4 with metadata, 1 without)

Tip: Use /wtm-adopt to add metadata to worktrees that lack it
```

### Step 4: Highlight Current Worktree

If one of the worktrees matches current directory (from `git rev-parse --show-toplevel`):
- Mark it with `→` or `*` indicator
- Example: `→ /path/to/current-worktree`

## Output Examples

### Example 1: All Worktrees with Metadata

```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
→ /Users/joe/myapp            main                main         Main development
  /Users/joe/myapp-feat-api   feature/api-v2      feature      New API endpoints
  /Users/joe/myapp-fix-bug    bugfix/login-bug    bugfix       Fix login redirect

═══════════════════════════════════════════════════════════════════════════════
Total: 3 worktrees (3 with metadata)
```

### Example 2: Mixed Metadata Status

```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
  /Users/joe/myapp            main                (no metadata) -
→ /Users/joe/myapp-feature    feature/new-thing   feature      New feature work
  /Users/joe/old-checkout     feature/abandoned   (no metadata) -

═══════════════════════════════════════════════════════════════════════════════
Total: 3 worktrees (1 with metadata, 2 without)

Tip: Use /wtm-adopt to add metadata to worktrees that lack it
```

### Example 3: No Worktrees (Only Main Repo)

```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
→ /Users/joe/myapp            main                (no metadata) -

═══════════════════════════════════════════════════════════════════════════════
Total: 1 worktree (main repository only)

To create a new worktree: /wtm-new <branch-name>
```

## Error Handling

### Not in Git Repository
```
Error: Not in a git repository

Run this command from within a git repository.
```

### Git Command Failed
```
Error: Failed to list worktrees

Git error: <error message>

Check that:
  - You're in a git repository
  - Git is installed and working
```

### Invalid JSON in Metadata File
```
Warning: Invalid .ai-context.json in /path/to/worktree

Displaying worktree without metadata. Consider:
  - Fixing the JSON manually
  - Running /wtm-adopt in that worktree to regenerate
```

## Display Format Options

### Compact Format (Default)
Table with fixed-width columns, truncate long descriptions.

### Verbose Format (Optional Enhancement)
```
Worktree 1/3
  Path:        /Users/joe/myapp-feature-login
  Branch:      feature/login-refactor
  Mode:        feature
  Created:     2025-11-23T10:30:00Z
  Description: Refactor authentication flow to support OAuth2

Worktree 2/3
  Path:        /Users/joe/myapp-bugfix-auth
  Branch:      bugfix/session-timeout
  Mode:        bugfix
  Created:     2025-11-23T14:20:00Z
  Description: Fix session timeout bug in middleware
```

Use compact format by default. Verbose can be added later if needed.

## Implementation Notes

- Parse `git worktree list --porcelain` output carefully
  - Each worktree is separated by blank line
  - Extract path from `worktree` line
  - Extract branch from `branch refs/heads/` line
- For each path, try to read `<path>/.ai-context.json`
- Handle missing or invalid JSON gracefully (show "no metadata", don't error)
- Detect current worktree by comparing paths
- Format table with aligned columns (use string padding)
- Truncate long descriptions to fit table width
- Count total worktrees and metadata status

## Related

- `/wtm-status` - Show current worktree details
- `/wtm-new` - Create new worktree with metadata
- `/wtm-adopt` - Add metadata to existing worktree
- `/wtm-destroy` - Remove worktree
- For organizing multiple worktrees strategically, invoke the `working-tree-consultant` agent

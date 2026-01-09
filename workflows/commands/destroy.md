---
description: Safely remove a git worktree and its metadata (preserves branch)
argument-hint: <worktree-path>
allowed-tools: Bash, Read
model: sonnet
hooks:
  PreToolUse:
    # Verify we're in a git repository
    - match: "Bash"
      script: |
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          echo "ERROR: Not in a git repository"
          exit 1
        fi
      once: true
    # Check for uncommitted changes before destructive operations
    - match: "Bash"
      script: |
        # Only warn for git worktree remove commands
        if [[ "$TOOL_INPUT" == *"git worktree remove"* ]]; then
          WORKTREE_PATH=$(echo "$TOOL_INPUT" | grep -oE '/[^ ]+' | head -1)
          if [[ -n "$WORKTREE_PATH" ]] && [[ -d "$WORKTREE_PATH" ]]; then
            cd "$WORKTREE_PATH" 2>/dev/null && \
            if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
              echo "WARNING: Worktree has uncommitted changes"
            fi
          fi
        fi
  PostToolUse:
    # Verify worktree was successfully removed
    - match: "Bash"
      script: |
        if [[ "$TOOL_INPUT" == *"git worktree remove"* ]]; then
          WORKTREE_PATH=$(echo "$TOOL_INPUT" | grep -oE '/[^ ]+' | head -1)
          if [[ -n "$WORKTREE_PATH" ]] && [[ -d "$WORKTREE_PATH" ]]; then
            echo "WARNING: Worktree directory still exists after removal attempt"
          fi
        fi
---

# /destroy:working-tree

Safely remove git worktree directory and metadata files. Branch is preserved.

## ARGUMENT SPECIFICATION

```
SYNTAX: /destroy:working-tree <worktree-path>

REQUIRED:
  <worktree-path>
    Type: path (absolute or relative)
    Validation: Must be registered git worktree
    Examples: "../myapp-feature-login", "/Users/dev/myapp-feature-login"
```

## EXECUTION PROTOCOL

Execute steps sequentially. Each step must complete successfully before proceeding.

### STEP 1: VALIDATE AND RESOLVE WORKTREE PATH

EXECUTE:
```bash
# Resolve to absolute path
if [[ "$WORKTREE_PATH_ARG" = /* ]]; then
    WORKTREE_PATH="$WORKTREE_PATH_ARG"
else
    WORKTREE_PATH=$(cd "$(dirname "$WORKTREE_PATH_ARG")" && pwd)/$(basename "$WORKTREE_PATH_ARG")
fi
```

VALIDATION:
- IF WORKTREE_PATH_ARG is empty → ERROR PATTERN "missing-path"
- WORKTREE_PATH must be absolute after resolution

NEXT:
- On success → STEP 2
- On failure → ABORT

### STEP 2: CHECK PATH EXISTS

EXECUTE:
```bash
test -e "$WORKTREE_PATH"
EXISTS=$?
```

VALIDATION:
- IF EXISTS != 0 → ERROR PATTERN "path-not-exist"

NEXT:
- On EXISTS == 0 → STEP 3
- On EXISTS != 0 → ABORT

### STEP 3: GET ALL WORKTREES AND VALIDATE

EXECUTE:
```bash
WORKTREE_LIST=$(git worktree list --porcelain 2>&1)
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "git-command-failed"

PARSE WORKTREE_LIST:
```bash
# Extract all worktree paths and branches
# Format: worktree /path\nHEAD hash\nbranch refs/heads/name\n\n
CURRENT_MAIN=$(echo "$WORKTREE_LIST" | head -1 | cut -d' ' -f2)
IS_MAIN_REPO=false

if [ "$WORKTREE_PATH" = "$CURRENT_MAIN" ]; then
    IS_MAIN_REPO=true
fi

# Find worktree entry for target path
WORKTREE_ENTRY=$(echo "$WORKTREE_LIST" | grep -A 3 "^worktree $WORKTREE_PATH$")
IS_REGISTERED=$(echo "$WORKTREE_ENTRY" | wc -l)
```

VALIDATION:
- IF IS_MAIN_REPO == true → ERROR PATTERN "cannot-destroy-main"
- IF IS_REGISTERED == 0 → ERROR PATTERN "not-a-worktree"

DATA EXTRACTION:
```bash
BRANCH_REF=$(echo "$WORKTREE_ENTRY" | grep "^branch " | cut -d' ' -f2)
BRANCH_NAME=$(echo "$BRANCH_REF" | sed 's|refs/heads/||')
```

NEXT:
- On success → STEP 4
- On failure → ABORT

### STEP 4: CHECK FOR UNCOMMITTED CHANGES

EXECUTE:
```bash
cd "$WORKTREE_PATH"
GIT_STATUS=$(git status --porcelain 2>&1)
STATUS_EXIT=$?
```

VALIDATION:
- IF STATUS_EXIT != 0 → Warning (worktree may be corrupted, allow removal)

DETECTION:
```bash
if [ -n "$GIT_STATUS" ]; then
    HAS_CHANGES=true
else
    HAS_CHANGES=false
fi
```

ACTION:
- IF HAS_CHANGES == false → STEP 5 (proceed directly)
- IF HAS_CHANGES == true → Display warning, ask user confirmation

USER DECISION (if HAS_CHANGES == true):
```
⚠ Warning: Uncommitted changes detected

Modified files:
{GIT_STATUS output}

These changes will be lost if you proceed.

Recommendations:
  1. Commit changes: cd {WORKTREE_PATH} && git commit -am "message"
  2. Stash changes: cd {WORKTREE_PATH} && git stash
  3. Proceed anyway (changes will be lost)

Proceed with removal? (This will permanently delete uncommitted work)
```

Use AskUserQuestion:
- Option 1: "Cancel removal" → TERMINATE (no changes)
- Option 2: "Proceed with removal (discard changes)" → STEP 5

NEXT:
- IF user cancels → TERMINATE
- IF user proceeds OR no changes → STEP 5

### STEP 5: REMOVE WORKTREE

EXECUTE:
```bash
git worktree remove --force "$WORKTREE_PATH" 2>&1
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "worktree-removal-failed"

NEXT:
- On success → STEP 6
- On failure → ABORT

### STEP 6: PRUNE STALE REFERENCES

EXECUTE:
```bash
git worktree prune 2>&1
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → Warning (not fatal, removal succeeded)

NEXT:
- On success → STEP 7
- On warning → STEP 7 (continue)

### STEP 7: OUTPUT SUCCESS SUMMARY

OUTPUT FORMAT (exact):
```
✓ Worktree removed successfully

  Path: {WORKTREE_PATH}
  Branch: {BRANCH_NAME}

Branch '{BRANCH_NAME}' has been preserved.

To delete the branch as well:
  git branch -d {BRANCH_NAME}   # Safe delete (only if merged)
  git branch -D {BRANCH_NAME}   # Force delete (even if unmerged)

To delete remote branch:
  git push origin --delete {BRANCH_NAME}
```

SUBSTITUTIONS:
- {WORKTREE_PATH} = from STEP 1
- {BRANCH_NAME} = from STEP 3

NEXT:
- TERMINATE (success)

## ERROR PATTERNS

### PATTERN: missing-path

DETECTION:
- TRIGGER: WORKTREE_PATH_ARG is empty (no argument provided)

RESPONSE (exact):
```
Error: Missing worktree path

Usage:
  /destroy:working-tree <worktree-path>

Example:
  /destroy:working-tree ../myapp-feature-login

To see all worktrees:
  /list:working-tree
```

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: path-not-exist

DETECTION:
- TRIGGER: Provided path does not exist (STEP 2)

RESPONSE (exact):
```
Error: Path does not exist

Path: {WORKTREE_PATH}

The specified path doesn't exist. Check for typos.

To list existing worktrees:
  /list:working-tree
```

TEMPLATE SUBSTITUTIONS:
- {WORKTREE_PATH} = provided path

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: git-command-failed

DETECTION:
- TRIGGER: git worktree list command fails (STEP 3)
- CAPTURE: stderr from git command

RESPONSE (exact):
```
Error: Failed to list worktrees

Git error: {GIT_STDERR}

Check that:
  - You're in a git repository
  - Git is installed and working
```

TEMPLATE SUBSTITUTIONS:
- {GIT_STDERR} = captured stderr

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: cannot-destroy-main

DETECTION:
- TRIGGER: Target path matches main repository path (STEP 3)

RESPONSE (exact):
```
Error: Cannot destroy main repository

The path '{WORKTREE_PATH}' is the main repository, not a worktree.

To remove worktrees, use paths like:
  /destroy:working-tree ../myapp-feature-branch
  /destroy:working-tree ../myapp-bugfix-something

To see all worktrees:
  /list:working-tree
```

TEMPLATE SUBSTITUTIONS:
- {WORKTREE_PATH} = main repository path

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: not-a-worktree

DETECTION:
- TRIGGER: Path exists but is not registered as git worktree (STEP 3)

RESPONSE (exact):
```
Error: Not a registered git worktree

Path: {WORKTREE_PATH}

This path is not a git worktree. To see all worktrees:
  /list:working-tree

Valid worktree paths look like:
  /Users/dev/myapp-feature-login
  ../myapp-bugfix-auth
```

TEMPLATE SUBSTITUTIONS:
- {WORKTREE_PATH} = provided path

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: worktree-removal-failed

DETECTION:
- TRIGGER: git worktree remove fails (STEP 5)
- CAPTURE: stderr from git worktree remove

RESPONSE (exact):
```
Error: Failed to remove worktree

Git error: {GIT_STDERR}

This can happen if:
  - Worktree is locked
  - Permission issues
  - Worktree is corrupted

Try:
  - Check file permissions
  - Run: git worktree prune
  - Manually remove directory and run: git worktree prune
```

TEMPLATE SUBSTITUTIONS:
- {GIT_STDERR} = captured stderr

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

## TOOL PERMISSION MATRIX

| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| Bash | git worktree:* | ALLOW | command_safe | validate_output | N/A |
| Bash | git status:* | ALLOW | command_safe | N/A | N/A |
| Bash | git branch:* | DENY | N/A | N/A | ABORT "Cannot delete branches automatically" |
| Bash | cd:* | ALLOW | N/A | N/A | N/A |
| Bash | test:* | ALLOW | N/A | N/A | N/A |
| Bash | pwd:* | ALLOW | N/A | N/A | N/A |
| Bash | dirname:* | ALLOW | N/A | N/A | N/A |
| Bash | basename:* | ALLOW | N/A | N/A | N/A |
| Bash | grep:* | ALLOW | N/A | N/A | N/A |
| Bash | sed:* | ALLOW | N/A | N/A | N/A |
| Bash | cut:* | ALLOW | N/A | N/A | N/A |
| Bash | wc:* | ALLOW | N/A | N/A | N/A |
| Bash | head:* | ALLOW | N/A | N/A | N/A |
| Bash | rm:* | DENY | N/A | N/A | ABORT "Use git worktree remove" |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Read | * | DENY | N/A | N/A | ABORT "Destroy is read-only except git" |
| Write | * | DENY | N/A | N/A | ABORT "Destroy does not write files" |

SECURITY CONSTRAINTS:
- Can ONLY remove worktrees via git worktree remove
- CANNOT delete branches (user must do manually)
- CANNOT use rm/rmdir (git manages removal)
- MUST check for uncommitted changes
- MUST prevent main repository deletion

## TEST CASES

### TC001: Remove worktree with no uncommitted changes

PRECONDITIONS:
- Worktree exists at /Users/dev/myapp-feature-login
- Branch: feature/login
- No uncommitted changes
- Not the main repository

INPUT:
```
/destroy:working-tree /Users/dev/myapp-feature-login
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → WORKTREE_PATH="/Users/dev/myapp-feature-login"
2. STEP 2 → EXISTS=0 (path exists)
3. STEP 3 → IS_MAIN_REPO=false, IS_REGISTERED>0, BRANCH_NAME="feature/login"
4. STEP 4 → HAS_CHANGES=false (no uncommitted changes)
5. STEP 5 → git worktree remove succeeds
6. STEP 6 → git worktree prune succeeds
7. STEP 7 → Output summary

EXPECTED OUTPUT:
```
✓ Worktree removed successfully

  Path: /Users/dev/myapp-feature-login
  Branch: feature/login

Branch 'feature/login' has been preserved.

To delete the branch as well:
  git branch -d feature/login   # Safe delete (only if merged)
  git branch -D feature/login   # Force delete (even if unmerged)

To delete remote branch:
  git push origin --delete feature/login
```

VALIDATION COMMANDS:
```bash
# Verify worktree no longer exists
test ! -e /Users/dev/myapp-feature-login && echo "PASS" || echo "FAIL"

# Verify branch still exists
git show-ref --verify refs/heads/feature/login && echo "PASS" || echo "FAIL"

# Verify not in worktree list
git worktree list | grep -v "feature-login" && echo "PASS" || echo "FAIL"
```

### TC002: Remove worktree with uncommitted changes - user proceeds

PRECONDITIONS:
- Worktree exists at /Users/dev/myapp-bugfix-auth
- Has uncommitted changes: Modified src/auth.ts

INPUT:
```
/destroy:working-tree /Users/dev/myapp-bugfix-auth
```

EXPECTED EXECUTION FLOW:
1-3. Standard detection
4. STEP 4 → HAS_CHANGES=true
5. Display warning with git status output
6. USER SELECTS "Proceed with removal (discard changes)"
7. STEP 5 → git worktree remove --force succeeds
8. STEP 6-7 → Standard cleanup and output

EXPECTED OUTPUT (includes warning):
```
⚠ Warning: Uncommitted changes detected

Modified files:
 M src/auth.ts

These changes will be lost if you proceed.

Recommendations:
  1. Commit changes: cd /Users/dev/myapp-bugfix-auth && git commit -am "message"
  2. Stash changes: cd /Users/dev/myapp-bugfix-auth && git stash
  3. Proceed anyway (changes will be lost)

Proceed with removal? (This will permanently delete uncommitted work)

[User confirms]

✓ Worktree removed successfully

  Path: /Users/dev/myapp-bugfix-auth
  Branch: bugfix/auth

Branch 'bugfix/auth' has been preserved.

To delete the branch as well:
  git branch -d bugfix/auth   # Safe delete (only if merged)
  git branch -D bugfix/auth   # Force delete (even if unmerged)

To delete remote branch:
  git push origin --delete bugfix/auth
```

### TC003: Remove worktree with uncommitted changes - user cancels

PRECONDITIONS:
- Worktree with uncommitted changes

INPUT:
```
/destroy:working-tree /Users/dev/myapp-feature-test
```

EXPECTED EXECUTION FLOW:
1-4. Detect changes
5. Display warning
6. USER SELECTS "Cancel removal"
7. TERMINATE (no changes)

EXPECTED OUTPUT:
```
⚠ Warning: Uncommitted changes detected

[warning displayed]

Proceed with removal?

[User cancels]

Removal cancelled. No changes made.
```

POSTCONDITIONS:
- Worktree still exists
- No files modified

### TC004: Attempt to destroy main repository

PRECONDITIONS:
- Main repository at /Users/dev/myapp

INPUT:
```
/destroy:working-tree /Users/dev/myapp
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → Resolve path
2. STEP 2 → Path exists
3. STEP 3 → IS_MAIN_REPO=true
4. ERROR PATTERN "cannot-destroy-main"
5. ABORT

EXPECTED OUTPUT:
```
Error: Cannot destroy main repository

The path '/Users/dev/myapp' is the main repository, not a worktree.

To remove worktrees, use paths like:
  /destroy:working-tree ../myapp-feature-branch
  /destroy:working-tree ../myapp-bugfix-something

To see all worktrees:
  /list:working-tree
```

POSTCONDITIONS:
- Main repository untouched
- No changes made

### TC005: Path does not exist

PRECONDITIONS:
- Path /Users/dev/nonexistent does not exist

INPUT:
```
/destroy:working-tree /Users/dev/nonexistent
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → Resolve path
2. STEP 2 → EXISTS=1 (does not exist)
3. ERROR PATTERN "path-not-exist"
4. ABORT

EXPECTED OUTPUT:
```
Error: Path does not exist

Path: /Users/dev/nonexistent

The specified path doesn't exist. Check for typos.

To list existing worktrees:
  /list:working-tree
```

### TC006: Not a git worktree

PRECONDITIONS:
- Directory /Users/dev/random-dir exists but is not a git worktree

INPUT:
```
/destroy:working-tree /Users/dev/random-dir
```

EXPECTED EXECUTION FLOW:
1-2. Resolve and verify path exists
3. STEP 3 → IS_REGISTERED=0 (not in worktree list)
4. ERROR PATTERN "not-a-worktree"
5. ABORT

EXPECTED OUTPUT:
```
Error: Not a registered git worktree

Path: /Users/dev/random-dir

This path is not a git worktree. To see all worktrees:
  /list:working-tree

Valid worktree paths look like:
  /Users/dev/myapp-feature-login
  ../myapp-bugfix-auth
```

## SAFETY FEATURES

### PROTECTED OPERATIONS
- CANNOT remove main repository
- WARNS about uncommitted changes
- REQUIRES confirmation for destructive operations
- PRESERVES branch by default

### BRANCH DELETION GUIDANCE

Command provides guidance but NEVER auto-deletes branches:

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

## RELATED COMMANDS

- /list:working-tree - See all worktrees before deciding what to remove
- /status:working-tree - Check current worktree before removing
- /create:working-tree - Create new worktree after removal

## DELEGATION

For guidance on when to remove worktrees:
```
Task(
  subagent_type='working-tree-consultant',
  description='Worktree removal strategy',
  prompt='[question about when/how to safely remove worktrees]'
)
```

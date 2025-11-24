---
description: List all git worktrees with their associated .ai-context metadata
allowed-tools: Bash, Read, Glob
model: sonnet
---

# /list:working-tree

Enumerate all git worktrees and display metadata from `.ai-context.json`.

## ARGUMENT SPECIFICATION

```
SYNTAX: /list:working-tree

NO ARGUMENTS
```

## EXECUTION PROTOCOL

Execute steps sequentially. Each step must complete successfully before proceeding.

### STEP 1: GET CURRENT WORKTREE

EXECUTE:
```bash
CURRENT_ROOT=$(git rev-parse --show-toplevel 2>&1)
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "not-in-git-repo"

NEXT:
- On success → STEP 2
- On failure → ABORT

### STEP 2: LIST ALL WORKTREES

EXECUTE:
```bash
WORKTREE_LIST=$(git worktree list --porcelain 2>&1)
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "git-command-failed"

NEXT:
- On success → STEP 3
- On failure → ABORT

### STEP 3: PARSE WORKTREES

PARSE FORMAT:
```
worktree /path/to/worktree
HEAD commit-hash
branch refs/heads/branch-name

worktree /another/path
HEAD commit-hash
branch refs/heads/another-branch
```

PARSING ALGORITHM:
```python
worktrees = []
current_entry = {}

for line in WORKTREE_LIST.split("\n"):
    if line.startswith("worktree "):
        if current_entry:
            worktrees.append(current_entry)
        current_entry = {"path": line.split(" ", 1)[1]}
    elif line.startswith("branch refs/heads/"):
        current_entry["branch"] = line.split("/")[-1]
    elif line == "":
        if current_entry:
            worktrees.append(current_entry)
            current_entry = {}

if current_entry:
    worktrees.append(current_entry)
```

DATA EXTRACTED:
- List of worktree entries, each with:
  - path: absolute path to worktree
  - branch: branch name (without refs/heads/)

NEXT:
- On success → STEP 4
- No failure case (empty list is valid)

### STEP 4: READ METADATA FOR EACH WORKTREE

FOR EACH worktree in worktrees:
```bash
METADATA_PATH="$worktree_path/.ai-context.json"
test -f "$METADATA_PATH"
HAS_METADATA=$?

if [ $HAS_METADATA -eq 0 ]; then
    METADATA=$(cat "$METADATA_PATH" 2>&1)
    MODE=$(echo "$METADATA" | jq -r '.mode // "(invalid)"' 2>&1)
    DESCRIPTION=$(echo "$METADATA" | jq -r '.description // ""' 2>&1)

    # Validate JSON
    if [ $? -ne 0 ]; then
        MODE="(invalid json)"
        DESCRIPTION=""
    fi
else
    MODE="(no metadata)"
    DESCRIPTION="-"
fi
```

DATA STRUCTURE:
```
worktree_data = [
    {
        "path": "/path/to/worktree",
        "branch": "feature/login",
        "mode": "feature",
        "description": "OAuth refactor",
        "is_current": true/false,
        "has_metadata": true/false
    },
    ...
]
```

CURRENT DETECTION:
- IF worktree_path == CURRENT_ROOT → is_current = true

NEXT:
- On success → STEP 5
- Continue even if individual metadata reads fail

### STEP 5: FORMAT AND DISPLAY TABLE

TABLE FORMAT:
```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
{INDICATOR} {PATH}  {BRANCH}  {MODE}  {DESCRIPTION}
...

═══════════════════════════════════════════════════════════════════════════════
Total: {COUNT} worktrees ({WITH_META} with metadata, {WITHOUT_META} without)

{TIP_IF_MISSING_METADATA}
```

FORMATTING RULES:
- INDICATOR: "→" if is_current, else "  " (2 spaces)
- PATH: Truncate to 30 chars if longer, add "..." suffix
- BRANCH: Truncate to 20 chars if longer
- MODE: Truncate to 12 chars
- DESCRIPTION: Truncate to 40 chars if longer, add "..."
- Align columns with padding

PADDING ALGORITHM:
```python
def pad_column(text, width):
    if len(text) > width:
        return text[:width-3] + "..."
    return text + " " * (width - len(text))
```

TIP LOGIC:
- IF any worktree has has_metadata == false:
  - Display: "Tip: Use /adopt:working-tree to add metadata to worktrees that lack it"

NEXT:
- On success → STEP 6
- No failure case

### STEP 6: COUNT AND SUMMARIZE

COUNTS:
```bash
TOTAL=$(echo "$worktrees" | wc -l)
WITH_META=$(count worktrees where has_metadata == true)
WITHOUT_META=$(count worktrees where has_metadata == false)
```

SUMMARY LINE:
```
Total: {TOTAL} worktrees ({WITH_META} with metadata, {WITHOUT_META} without)
```

SPECIAL CASES:
- IF TOTAL == 1 AND WITHOUT_META == 1:
  - Summary: "Total: 1 worktree (main repository only)"
  - Tip: "To create a new worktree: /create:working-tree <branch-name>"

NEXT:
- TERMINATE (success)

## ERROR PATTERNS

### PATTERN: not-in-git-repo

DETECTION:
- TRIGGER: git rev-parse --show-toplevel exit code != 0
- INDICATORS: stderr contains "not a git repository"

RESPONSE (exact):
```
Error: Not in a git repository

Run this command from within a git repository.
```

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: git-command-failed

DETECTION:
- TRIGGER: git worktree list command fails (STEP 2)
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

### PATTERN: invalid-metadata-json

DETECTION:
- TRIGGER: jq fails to parse .ai-context.json (STEP 4)
- OCCURS: per-worktree, not fatal

RESPONSE:
```
Warning: Invalid .ai-context.json in {WORKTREE_PATH}

Displaying worktree without metadata. Consider:
  - Fixing the JSON manually
  - Running /adopt:working-tree in that worktree to regenerate
```

CONTROL FLOW:
- ABORT: false (warning only)
- DISPLAY: Show worktree with MODE="(invalid json)"
- CONTINUE: Process remaining worktrees

## TOOL PERMISSION MATRIX

| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| Bash | git worktree:* | ALLOW | command_safe | N/A | N/A |
| Bash | git rev-parse:* | ALLOW | command_safe | N/A | N/A |
| Bash | test:* | ALLOW | N/A | N/A | N/A |
| Bash | cat:* | ALLOW | N/A | N/A | N/A |
| Bash | jq:* | ALLOW | N/A | N/A | N/A |
| Bash | wc:* | ALLOW | N/A | N/A | N/A |
| Bash | grep:* | ALLOW | N/A | N/A | N/A |
| Bash | cut:* | ALLOW | N/A | N/A | N/A |
| Bash | sed:* | ALLOW | N/A | N/A | N/A |
| Bash | head:* | ALLOW | N/A | N/A | N/A |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Read | */.ai-context.json | ALLOW | N/A | N/A | N/A |
| Write | * | DENY | N/A | N/A | ABORT "List is read-only" |
| Edit | * | DENY | N/A | N/A | ABORT "List is read-only" |

SECURITY CONSTRAINTS:
- Command is READ-ONLY
- Cannot modify any files
- Cannot execute destructive operations
- Safe to run multiple times

## TEST CASES

### TC001: Multiple worktrees with metadata

PRECONDITIONS:
- Main repository at /Users/dev/myapp
- Worktree at /Users/dev/myapp-feature-api with metadata (mode: feature, description: "New API")
- Worktree at /Users/dev/myapp-bugfix-auth with metadata (mode: bugfix, description: "Fix auth")
- Currently in /Users/dev/myapp

INPUT:
```
/list:working-tree
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → CURRENT_ROOT="/Users/dev/myapp"
2. STEP 2 → Get worktree list
3. STEP 3 → Parse 3 worktrees
4. STEP 4 → Read metadata for each
5. STEP 5-6 → Format and display

EXPECTED OUTPUT:
```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
→ /Users/dev/myapp            main                main         Main development
  /Users/dev/myapp-feature... feature/api         feature      New API
  /Users/dev/myapp-bugfix-... bugfix/auth         bugfix       Fix auth

═══════════════════════════════════════════════════════════════════════════════
Total: 3 worktrees (3 with metadata)
```

VALIDATION:
- Current worktree marked with →
- All columns aligned
- Counts correct

### TC002: Mixed metadata status

PRECONDITIONS:
- Main repository without metadata
- One worktree with metadata
- One worktree without metadata

INPUT:
```
/list:working-tree
```

EXPECTED OUTPUT:
```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
  /Users/dev/myapp            main                (no metadata) -
→ /Users/dev/myapp-feature... feature/new         feature      New feature work
  /Users/dev/old-checkout     feature/abandoned   (no metadata) -

═══════════════════════════════════════════════════════════════════════════════
Total: 3 worktrees (1 with metadata, 2 without)

Tip: Use /adopt:working-tree to add metadata to worktrees that lack it
```

VALIDATION:
- Tip displayed because some worktrees lack metadata
- (no metadata) shown for worktrees without .ai-context.json

### TC003: Only main repository

PRECONDITIONS:
- Main repository only, no additional worktrees
- No metadata file

INPUT:
```
/list:working-tree
```

EXPECTED OUTPUT:
```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
→ /Users/dev/myapp            main                (no metadata) -

═══════════════════════════════════════════════════════════════════════════════
Total: 1 worktree (main repository only)

To create a new worktree: /create:working-tree <branch-name>
```

VALIDATION:
- Special message for single worktree
- Tip suggests creating worktree

### TC004: Invalid JSON in metadata file

PRECONDITIONS:
- Worktree at /Users/dev/myapp-test
- File exists: /Users/dev/myapp-test/.ai-context.json
- File contains invalid JSON: `{invalid`

INPUT:
```
/list:working-tree
```

EXPECTED EXECUTION FLOW:
1-3. Standard flow
4. STEP 4 → jq fails on invalid JSON
5. Display warning
6. Show worktree with MODE="(invalid json)"
7. Continue with other worktrees

EXPECTED OUTPUT:
```
Warning: Invalid .ai-context.json in /Users/dev/myapp-test

Displaying worktree without metadata. Consider:
  - Fixing the JSON manually
  - Running /adopt:working-tree in that worktree to regenerate

Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
→ /Users/dev/myapp-test       feature/test        (invalid json) -

═══════════════════════════════════════════════════════════════════════════════
Total: 1 worktree (0 with metadata, 1 without)

Tip: Use /adopt:working-tree to add metadata to worktrees that lack it
```

### TC005: Long paths and descriptions

PRECONDITIONS:
- Worktree with very long path: /Users/dev/myapp-feature-really-long-branch-name-that-exceeds-column-width
- Description: "This is a very long description that exceeds the maximum column width and should be truncated"

INPUT:
```
/list:working-tree
```

EXPECTED OUTPUT:
```
Git Worktrees
═══════════════════════════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────────────────────────
→ /Users/dev/myapp-feature... feature/really-lo... feature      This is a very long description that...

═══════════════════════════════════════════════════════════════════════════════
Total: 1 worktree (1 with metadata)
```

VALIDATION:
- Long path truncated with "..."
- Long branch truncated with "..."
- Long description truncated with "..."
- Columns remain aligned

## DISPLAY NOTES

### COLUMN WIDTHS

Fixed widths for consistent alignment:
- Indicator: 2 chars ("→ " or "  ")
- Path: 30 chars
- Branch: 20 chars
- Mode: 13 chars
- Description: remaining width (or 40 chars minimum)

### TRUNCATION STRATEGY

```python
def truncate(text, max_width):
    if len(text) <= max_width:
        return text
    return text[:max_width-3] + "..."
```

### BOX DRAWING

Use consistent box-drawing characters:
- Top/bottom: `═` (double horizontal)
- Separator: `─` (single horizontal)
- No vertical bars (cleaner appearance)

## RELATED COMMANDS

- /status:working-tree - Show current worktree details
- /create:working-tree - Create new worktree with metadata
- /adopt:working-tree - Add metadata to existing worktree
- /destroy:working-tree - Remove worktree

## DELEGATION

For organizing multiple worktrees strategically:
```
Task(
  subagent_type='working-tree-consultant',
  description='Worktree organization strategy',
  prompt='[question about managing multiple worktrees]'
)
```

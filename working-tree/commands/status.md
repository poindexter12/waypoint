---
description: Show metadata for the current git worktree from .ai-context.json
allowed-tools: Bash, Read
model: sonnet
---

# /working-tree:status

Display current worktree AI context metadata and git information.

## EXECUTION PROTOCOL

Execute steps sequentially. Each step must complete successfully before proceeding.

### STEP 1: DETECT REPOSITORY ROOT

EXECUTE:
```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>&1)
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "not-in-git-repo"
- REPO_ROOT must be absolute path starting with /
- REPO_ROOT directory must exist

DATA EXTRACTION:
- REPO_NAME = basename of REPO_ROOT

NEXT:
- On success → STEP 2
- On failure → ABORT

### STEP 2: DETECT CURRENT BRANCH

EXECUTE:
```bash
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>&1)
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "git-command-failed"
- BRANCH_NAME must not be empty string

NEXT:
- On success → STEP 3
- On failure → ABORT

### STEP 3: CHECK METADATA FILE

EXECUTE:
```bash
METADATA_PATH="$REPO_ROOT/.ai-context.json"
test -f "$METADATA_PATH"
EXISTS=$?
```

VALIDATION:
- EXISTS is 0 (true) or 1 (false), no other values

NEXT:
- IF EXISTS == 0 → STEP 4 (metadata exists)
- IF EXISTS == 1 → STEP 5 (no metadata)

### STEP 4: READ AND PARSE METADATA

EXECUTE:
```bash
METADATA_JSON=$(cat "$METADATA_PATH" 2>&1)
CAT_EXIT=$?
```

VALIDATION:
- IF CAT_EXIT != 0 → ERROR PATTERN "file-read-failed"

DATA EXTRACTION:
```bash
MODE=$(echo "$METADATA_JSON" | jq -r '.mode // "unknown"' 2>&1)
JQ_EXIT_MODE=$?
DESCRIPTION=$(echo "$METADATA_JSON" | jq -r '.description // ""' 2>&1)
JQ_EXIT_DESC=$?
CREATED=$(echo "$METADATA_JSON" | jq -r '.created // ""' 2>&1)
JQ_EXIT_CREATED=$?
```

VALIDATION:
- IF JQ_EXIT_MODE != 0 → ERROR PATTERN "invalid-json"
- MODE must be one of: main, feature, bugfix, experiment, review, unknown
- DESCRIPTION can be empty string
- CREATED should be ISO8601 format or empty

NEXT:
- On success → STEP 6 (display with metadata)
- On jq failure → ERROR PATTERN "invalid-json"

### STEP 5: DISPLAY NO METADATA

OUTPUT FORMAT (exact):
```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    {REPO_NAME}
Branch:       {BRANCH_NAME}
Mode:         (no metadata)

⚠ No .ai-context.json found

This worktree doesn't have AI context metadata.

To add metadata to this worktree:
  /working-tree:adopt [--mode <mode>] [--description "<text>"]

To create a new worktree with metadata:
  /working-tree:new <branch-name>
```

NEXT:
- TERMINATE (success)

### STEP 6: DISPLAY WITH METADATA

OUTPUT FORMAT (exact):
```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    {REPO_NAME}
Branch:       {BRANCH_NAME}
Mode:         {MODE}
Created:      {CREATED}

Purpose:
{DESCRIPTION or "No description provided"}

───────────────────────────────────────────────────────────

Mode Semantics:
  main       → Minimal changes, stable work only
  feature    → Active development, larger changes allowed
  bugfix     → Isolated, surgical fixes only
  experiment → Prototypes, large swings, unsafe changes allowed
  review     → Documentation, analysis, audits

Metadata file: .ai-context.json
```

TEMPLATE SUBSTITUTIONS:
- {REPO_NAME} = extracted from STEP 1
- {BRANCH_NAME} = extracted from STEP 2
- {MODE} = extracted from STEP 4
- {CREATED} = extracted from STEP 4
- {DESCRIPTION} = extracted from STEP 4, if empty use "No description provided"

NEXT:
- TERMINATE (success)

## ERROR PATTERNS

### PATTERN: not-in-git-repo

DETECTION:
- TRIGGER: git rev-parse --show-toplevel exit code != 0
- INDICATORS: stderr contains "not a git repository" OR "not inside a work tree"

RESPONSE (exact):
```
Error: Not in a git repository

Run this command from within a git repository.
```

CONTROL FLOW:
- ABORT: true
- RETRY: false
- FALLBACK: None

### PATTERN: git-command-failed

DETECTION:
- TRIGGER: git command exit code != 0 (excluding rev-parse --show-toplevel which uses "not-in-git-repo")
- CAPTURE: stderr from failed git command

RESPONSE (exact):
```
Error: Failed to read git information

Git error: {GIT_STDERR}

Check that:
  - You're in a git repository
  - Git is installed and working
```

TEMPLATE SUBSTITUTIONS:
- {GIT_STDERR} = captured stderr from failed command

CONTROL FLOW:
- ABORT: true
- RETRY: false
- FALLBACK: None

### PATTERN: invalid-json

DETECTION:
- TRIGGER: jq command exit code != 0 when parsing .ai-context.json
- CAPTURE: jq error message from stderr

RESPONSE (exact):
```
Warning: .ai-context.json exists but is invalid

JSON error: {JQ_ERROR}

The metadata file may be corrupted. Consider:
  - Fixing the JSON manually
  - Running /working-tree:adopt to regenerate
```

TEMPLATE SUBSTITUTIONS:
- {JQ_ERROR} = captured stderr from jq

CONTROL FLOW:
- ABORT: false (warning, not error)
- RETRY: false
- FALLBACK: STEP 5 (display as if no metadata)

### PATTERN: file-read-failed

DETECTION:
- TRIGGER: cat command on .ai-context.json fails despite file existence check passing
- CAPTURE: stderr from cat command

RESPONSE (exact):
```
Error: Failed to read .ai-context.json

Read error: {CAT_ERROR}

Check file permissions on .ai-context.json
```

TEMPLATE SUBSTITUTIONS:
- {CAT_ERROR} = captured stderr from cat

CONTROL FLOW:
- ABORT: true
- RETRY: false
- FALLBACK: None

## TOOL PERMISSION MATRIX

| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| Bash | git:* | ALLOW | command_safe | validate_output | N/A |
| Bash | jq:* | ALLOW | command_safe | validate_json | N/A |
| Bash | cat .ai-context.json | ALLOW | file_exists | validate_output | N/A |
| Bash | test:* | ALLOW | N/A | N/A | N/A |
| Bash | rm:* | DENY | N/A | N/A | ABORT "Destructive operation" |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Read | .ai-context.json | ALLOW | file_exists | valid_json | N/A |
| Write | ** | DENY | N/A | N/A | ABORT "Status is read-only" |
| Edit | ** | DENY | N/A | N/A | ABORT "Status is read-only" |

SECURITY CONSTRAINTS:
- This command is READ-ONLY
- NO file modifications allowed
- NO destructive operations allowed
- Git commands limited to read operations (rev-parse, status, etc.)

## TEST CASES

### TC001: Worktree with valid metadata

PRECONDITIONS:
- In git repository at /path/to/myapp
- Current branch: feature/login-refactor
- File exists: /path/to/myapp/.ai-context.json
- File contains valid JSON:
```json
{
  "mode": "feature",
  "description": "Refactor authentication flow to support OAuth2",
  "created": "2025-11-23T10:30:00Z",
  "branch": "feature/login-refactor"
}
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → REPO_ROOT="/path/to/myapp", REPO_NAME="myapp"
2. STEP 2 → BRANCH_NAME="feature/login-refactor"
3. STEP 3 → EXISTS=0 (metadata exists)
4. STEP 4 → MODE="feature", DESCRIPTION="Refactor authentication flow to support OAuth2", CREATED="2025-11-23T10:30:00Z"
5. STEP 6 → Display formatted output

EXPECTED OUTPUT:
```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    myapp
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

VALIDATION COMMANDS:
```bash
# Verify file exists
test -f /path/to/myapp/.ai-context.json && echo "PASS" || echo "FAIL"

# Verify valid JSON
jq empty /path/to/myapp/.ai-context.json && echo "PASS" || echo "FAIL"

# Verify mode field
test "$(jq -r '.mode' /path/to/myapp/.ai-context.json)" = "feature" && echo "PASS" || echo "FAIL"
```

### TC002: Worktree without metadata

PRECONDITIONS:
- In git repository at /path/to/myapp
- Current branch: main
- File does NOT exist: /path/to/myapp/.ai-context.json

EXPECTED EXECUTION FLOW:
1. STEP 1 → REPO_ROOT="/path/to/myapp", REPO_NAME="myapp"
2. STEP 2 → BRANCH_NAME="main"
3. STEP 3 → EXISTS=1 (no metadata)
4. STEP 5 → Display no-metadata output
5. TERMINATE

EXPECTED OUTPUT:
```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    myapp
Branch:       main
Mode:         (no metadata)

⚠ No .ai-context.json found

This worktree doesn't have AI context metadata.

To add metadata to this worktree:
  /working-tree:adopt [--mode <mode>] [--description "<text>"]

To create a new worktree with metadata:
  /working-tree:new <branch-name>
```

VALIDATION COMMANDS:
```bash
# Verify file does not exist
test ! -f /path/to/myapp/.ai-context.json && echo "PASS" || echo "FAIL"
```

### TC003: Invalid JSON in metadata file

PRECONDITIONS:
- In git repository at /path/to/myapp
- Current branch: feature/test
- File exists: /path/to/myapp/.ai-context.json
- File contains invalid JSON: `{invalid json}`

EXPECTED EXECUTION FLOW:
1. STEP 1 → REPO_ROOT="/path/to/myapp"
2. STEP 2 → BRANCH_NAME="feature/test"
3. STEP 3 → EXISTS=0
4. STEP 4 → jq fails with parse error
5. ERROR PATTERN "invalid-json" → Warning displayed
6. FALLBACK → STEP 5 (display as no metadata)

EXPECTED OUTPUT:
```
Warning: .ai-context.json exists but is invalid

JSON error: parse error: Invalid numeric literal at line 1, column 10

The metadata file may be corrupted. Consider:
  - Fixing the JSON manually
  - Running /working-tree:adopt to regenerate

Worktree Status
═══════════════════════════════════════════════════════════

Directory:    myapp
Branch:       feature/test
Mode:         (no metadata)

⚠ No .ai-context.json found

This worktree doesn't have AI context metadata.

To add metadata to this worktree:
  /working-tree:adopt [--mode <mode>] [--description "<text>"]

To create a new worktree with metadata:
  /working-tree:new <branch-name>
```

VALIDATION COMMANDS:
```bash
# Verify file exists but is invalid
test -f /path/to/myapp/.ai-context.json && echo "EXISTS"
jq empty /path/to/myapp/.ai-context.json 2>&1 | grep -q "parse error" && echo "INVALID"
```

### TC004: Not in git repository

PRECONDITIONS:
- Current directory: /tmp (not a git repository)

EXPECTED EXECUTION FLOW:
1. STEP 1 → git rev-parse fails with exit code 128
2. ERROR PATTERN "not-in-git-repo" triggered
3. ABORT

EXPECTED OUTPUT:
```
Error: Not in a git repository

Run this command from within a git repository.
```

VALIDATION COMMANDS:
```bash
# Verify not in git repo
cd /tmp
git rev-parse --show-toplevel 2>&1 | grep -q "not a git repository" && echo "PASS" || echo "FAIL"
```

## RELATED COMMANDS

- /working-tree:adopt - Add metadata to current worktree
- /working-tree:new - Create new worktree with metadata
- /working-tree:list - List all worktrees with metadata
- /working-tree:destroy - Remove worktree safely

## DELEGATION

For complex worktree strategy questions or multi-worktree workflows:
```
Task(
  subagent_type='working-tree-consultant',
  description='Worktree strategy consultation',
  prompt='[detailed question about worktree organization]'
)
```

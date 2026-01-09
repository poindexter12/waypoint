---
description: Add .ai-context.json metadata to an existing worktree
argument-hint: [--mode <mode>] [--description "<text>"]
allowed-tools: Bash, Write, Read
model: sonnet
hooks:
  PreToolUse:
    # Verify we're in a git worktree before any operations
    - match: "Bash"
      script: |
        if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
          echo "ERROR: Not in a git repository"
          exit 1
        fi
      once: true
  PostToolUse:
    # Validate metadata JSON after write operations
    - match: "Write"
      script: |
        if [[ "$TOOL_OUTPUT" == *".ai-context.json"* ]]; then
          FILE_PATH=$(echo "$TOOL_OUTPUT" | grep -o '/[^ ]*\.ai-context\.json' | head -1)
          if [[ -n "$FILE_PATH" ]] && [[ -f "$FILE_PATH" ]]; then
            if ! jq empty "$FILE_PATH" 2>/dev/null; then
              echo "WARNING: Generated .ai-context.json may have invalid JSON"
            fi
          fi
        fi
---

# /adopt:working-tree

Generate `.ai-context.json` and `README.working-tree.md` for existing worktree lacking metadata.

## ARGUMENT SPECIFICATION

```
SYNTAX: /adopt:working-tree [--mode <mode>] [--description "<text>"]

OPTIONAL:
  --mode <mode>
    Type: enum[main, feature, bugfix, experiment, review]
    Default: inferred from branch-name (see MODE_INFERENCE_ALGORITHM)
    Validation: must match exactly one of the enum values

  --description "<text>"
    Type: string (quoted if contains spaces)
    Default: "" (empty string)
    Validation: any string, no restrictions
```

## MODE_INFERENCE_ALGORITHM

APPLY rules sequentially, first match wins:

```python
def infer_mode(branch_name: str) -> str:
    if branch_name.startswith("feature/"):
        return "feature"
    elif branch_name.startswith(("bugfix/", "fix/")):
        return "bugfix"
    elif branch_name.startswith(("exp/", "experiment/")):
        return "experiment"
    elif branch_name.startswith("review/"):
        return "review"
    elif branch_name.startswith("i18n/"):
        return "feature"  # i18n work is feature-type work
    elif branch_name in ("main", "master"):
        return "main"
    else:
        return "feature"  # DEFAULT
```

DETERMINISTIC: Given same branch_name, always produces same mode.

## EXECUTION PROTOCOL

Execute steps sequentially. Each step must complete successfully before proceeding.

### STEP 1: DETECT REPOSITORY INFO

EXECUTE:
```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>&1)
EXIT_CODE_ROOT=$?
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>&1)
EXIT_CODE_BRANCH=$?
```

VALIDATION:
- IF EXIT_CODE_ROOT != 0 → ERROR PATTERN "not-in-git-repo"
- IF EXIT_CODE_BRANCH != 0 → ERROR PATTERN "git-command-failed"
- REPO_ROOT must be absolute path starting with /

DATA EXTRACTION:
```bash
WORKTREE_NAME=$(basename "$REPO_ROOT")
```

NEXT:
- On success → STEP 2
- On failure → ABORT

### STEP 2: CHECK EXISTING METADATA

EXECUTE:
```bash
METADATA_PATH="$REPO_ROOT/.ai-context.json"
test -f "$METADATA_PATH"
EXISTS=$?
```

VALIDATION:
- EXISTS is 0 (exists) or 1 (does not exist)

ACTION:
- IF EXISTS == 0 → STEP 3 (check for overwrite)
- IF EXISTS == 1 → STEP 4 (proceed with creation)

NEXT:
- Conditional based on EXISTS value

### STEP 3: HANDLE EXISTING METADATA

EXECUTE:
```bash
EXISTING_JSON=$(cat "$METADATA_PATH" 2>&1)
EXISTING_MODE=$(echo "$EXISTING_JSON" | jq -r '.mode // "unknown"' 2>&1)
EXISTING_DESC=$(echo "$EXISTING_JSON" | jq -r '.description // ""' 2>&1)
EXISTING_CREATED=$(echo "$EXISTING_JSON" | jq -r '.created // ""' 2>&1)
```

DISPLAY TO USER:
```
Current worktree already has metadata:

  Directory:    {WORKTREE_NAME}
  Branch:       {CURRENT_BRANCH}
  Mode:         {EXISTING_MODE}
  Created:      {EXISTING_CREATED}
  Description:  {EXISTING_DESC or "None"}

Do you want to overwrite this metadata?
```

USER DECISION (use AskUserQuestion):
- Option 1: "Keep existing metadata" → TERMINATE (no changes)
- Option 2: "Overwrite with new metadata" → STEP 4 (proceed)
- Option 3: "Cancel" → TERMINATE (no changes)

NEXT:
- IF user selects overwrite → STEP 4
- IF user selects keep/cancel → TERMINATE

### STEP 4: PARSE AND VALIDATE ARGUMENTS

PARSE:
```bash
# Parse --mode flag (if present)
if [[ "$@" =~ --mode[[:space:]]+([a-z]+) ]]; then
    MODE_ARG="${BASH_REMATCH[1]}"
else
    MODE_ARG=""
fi

# Parse --description flag (if present)
if [[ "$@" =~ --description[[:space:]]+\"([^\"]+)\" ]]; then
    DESCRIPTION="${BASH_REMATCH[1]}"
elif [[ "$@" =~ --description[[:space:]]+([^[:space:]]+) ]]; then
    DESCRIPTION="${BASH_REMATCH[1]}"
else
    DESCRIPTION=""
fi
```

VALIDATION:
- IF MODE_ARG not empty AND MODE_ARG not in [main, feature, bugfix, experiment, review] → ERROR PATTERN "invalid-mode"

NEXT:
- On success → STEP 5
- On failure → ABORT

### STEP 5: DETERMINE MODE

EXECUTE:
```bash
if [ -n "$MODE_ARG" ]; then
    # Explicit mode provided
    MODE="$MODE_ARG"
else
    # Infer from branch name using MODE_INFERENCE_ALGORITHM
    case "$CURRENT_BRANCH" in
        feature/*)
            MODE="feature"
            ;;
        bugfix/*|fix/*)
            MODE="bugfix"
            ;;
        exp/*|experiment/*)
            MODE="experiment"
            ;;
        review/*)
            MODE="review"
            ;;
        i18n/*)
            MODE="feature"  # i18n work is feature-type work
            ;;
        main|master)
            MODE="main"
            ;;
        *)
            MODE="feature"
            ;;
    esac
fi
```

VALIDATION:
- MODE must be exactly one of: main, feature, bugfix, experiment, review
- MODE must not be empty

DATA:
- MODE = final determined mode (explicit or inferred)

NEXT:
- On success → STEP 6
- On failure → ABORT (should not occur if STEP 4 validation passed)

### STEP 6: GENERATE TIMESTAMP

EXECUTE:
```bash
CREATED_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

FORMAT: ISO 8601 UTC (example: 2025-11-23T12:34:56Z)

VALIDATION:
- CREATED_TIMESTAMP must match pattern: ^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$

NEXT:
- On success → STEP 7
- No failure case

### STEP 7: GENERATE .ai-context.json

CONTENT TEMPLATE:
```json
{
  "worktree": "{WORKTREE_NAME}",
  "branch": "{CURRENT_BRANCH}",
  "mode": "{MODE}",
  "created": "{CREATED_TIMESTAMP}",
  "description": "{DESCRIPTION}"
}
```

SUBSTITUTIONS:
- {WORKTREE_NAME} = from STEP 1
- {CURRENT_BRANCH} = from STEP 1
- {MODE} = from STEP 5
- {CREATED_TIMESTAMP} = from STEP 6
- {DESCRIPTION} = from STEP 4 (empty string if not provided)

EXECUTE:
```bash
cat > "$REPO_ROOT/.ai-context.json" <<EOF
{
  "worktree": "$WORKTREE_NAME",
  "branch": "$CURRENT_BRANCH",
  "mode": "$MODE",
  "created": "$CREATED_TIMESTAMP",
  "description": "$DESCRIPTION"
}
EOF
```

VALIDATION:
- File must be created at exact path: $REPO_ROOT/.ai-context.json
- File must contain valid JSON
- Verify with: `jq empty "$REPO_ROOT/.ai-context.json"`
- IF jq fails → ERROR PATTERN "metadata-write-failed"

NEXT:
- On success → STEP 8
- On failure → ABORT

### STEP 8: GENERATE README.working-tree.md (IF MISSING)

CHECK:
```bash
README_PATH="$REPO_ROOT/README.working-tree.md"
test -f "$README_PATH"
README_EXISTS=$?
```

ACTION:
- IF README_EXISTS == 0 (exists) → SKIP to STEP 9 (don't overwrite)
- IF README_EXISTS == 1 (missing) → Create README

CONTENT TEMPLATE:
```markdown
# Worktree: {WORKTREE_NAME}

**Branch:** `{CURRENT_BRANCH}`
**Mode:** `{MODE}`
**Created:** {CREATED_TIMESTAMP}

## Purpose

{DESCRIPTION_OR_DEFAULT}

## Mode Semantics

- **main**: Minimal changes, stable work only
- **feature**: Active development, larger changes allowed
- **bugfix**: Isolated, surgical fixes only
- **experiment**: Prototypes, large swings, unsafe changes allowed
- **review**: Documentation, analysis, audits

## About This Worktree

This directory is an independent Git worktree attached to the main repository.

- Main repo: {REPO_ROOT}
- Worktree path: {REPO_ROOT}
- Branch: {CURRENT_BRANCH}

See `.ai-context.json` for machine-readable metadata.
```

SUBSTITUTIONS:
- {WORKTREE_NAME} = from STEP 1
- {CURRENT_BRANCH} = from STEP 1
- {MODE} = from STEP 5
- {CREATED_TIMESTAMP} = from STEP 6
- {DESCRIPTION_OR_DEFAULT} = DESCRIPTION if not empty, else "No description provided"
- {REPO_ROOT} = from STEP 1

EXECUTE (only if README_EXISTS == 1):
```bash
DESCRIPTION_TEXT="${DESCRIPTION:-No description provided}"
cat > "$REPO_ROOT/README.working-tree.md" <<EOF
# Worktree: $WORKTREE_NAME

**Branch:** \`$CURRENT_BRANCH\`
**Mode:** \`$MODE\`
**Created:** $CREATED_TIMESTAMP

## Purpose

$DESCRIPTION_TEXT

## Mode Semantics

- **main**: Minimal changes, stable work only
- **feature**: Active development, larger changes allowed
- **bugfix**: Isolated, surgical fixes only
- **experiment**: Prototypes, large swings, unsafe changes allowed
- **review**: Documentation, analysis, audits

## About This Worktree

This directory is an independent Git worktree attached to the main repository.

- Main repo: $REPO_ROOT
- Worktree path: $REPO_ROOT
- Branch: $CURRENT_BRANCH

See \`.ai-context.json\` for machine-readable metadata.
EOF
```

VALIDATION:
- IF created, file must exist at: $REPO_ROOT/README.working-tree.md
- IF file creation failed → Warning (not fatal)

NEXT:
- On success or skip → STEP 9
- On failure → Warning (continue)

### STEP 9: OUTPUT SUCCESS SUMMARY

OUTPUT FORMAT (exact):
```
Adopted worktree successfully!

  Directory: {WORKTREE_NAME}
  Branch: {CURRENT_BRANCH}
  Mode: {MODE}
  Description: {DESCRIPTION_OR_NONE}

Metadata files created:
  ✓ .ai-context.json
  {README_STATUS}

Use /status:working-tree to view metadata anytime.
```

SUBSTITUTIONS:
- {WORKTREE_NAME} = from STEP 1
- {CURRENT_BRANCH} = from STEP 1
- {MODE} = from STEP 5
- {DESCRIPTION_OR_NONE} = DESCRIPTION if not empty, else "None"
- {README_STATUS} = "✓ README.working-tree.md (created)" if created, "- README.working-tree.md (already exists)" if skipped

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

To create a new worktree with metadata:
  /create:working-tree <branch-name>
```

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: git-command-failed

DETECTION:
- TRIGGER: Any git command (except rev-parse --show-toplevel) returns non-zero exit code
- CAPTURE: stderr from git command

RESPONSE (exact):
```
Error: Failed to read git information

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

### PATTERN: invalid-mode

DETECTION:
- TRIGGER: MODE_ARG provided but not in [main, feature, bugfix, experiment, review]

RESPONSE (exact):
```
Error: Invalid mode '{MODE_ARG}'

Valid modes: main, feature, bugfix, experiment, review

Example:
  /adopt:working-tree --mode feature --description "new feature work"
```

TEMPLATE SUBSTITUTIONS:
- {MODE_ARG} = the invalid mode provided

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: metadata-write-failed

DETECTION:
- TRIGGER: .ai-context.json write fails or invalid JSON (STEP 7)
- CHECK: jq validation fails

RESPONSE (exact):
```
Error: Failed to write .ai-context.json

Write error: {ERROR_MESSAGE}

Check that:
  - You have write permission in this directory
  - Disk space is available
  - No file conflicts exist
```

TEMPLATE SUBSTITUTIONS:
- {ERROR_MESSAGE} = error message from write operation

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: readme-write-failed

DETECTION:
- TRIGGER: README.working-tree.md write fails (STEP 8)

RESPONSE (exact):
```
Warning: Failed to write README.working-tree.md

The .ai-context.json was created successfully.

You can manually create the README if needed.
```

CONTROL FLOW:
- ABORT: false (warning, not critical)
- CLEANUP: none
- FALLBACK: Continue without README

## TOOL PERMISSION MATRIX

| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| Bash | git:* | ALLOW | command_safe | validate_output | N/A |
| Bash | date:* | ALLOW | N/A | N/A | N/A |
| Bash | test:* | ALLOW | N/A | N/A | N/A |
| Bash | basename:* | ALLOW | N/A | N/A | N/A |
| Bash | cat > *.json | ALLOW | dir_writable | valid_json | N/A |
| Bash | cat > *.md | ALLOW | dir_writable | N/A | N/A |
| Bash | jq:* | ALLOW | N/A | N/A | N/A |
| Bash | rm:* | DENY | N/A | N/A | ABORT "Destructive operation" |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Write | $REPO_ROOT/.ai-context.json | ALLOW | dir_exists | valid_json | N/A |
| Write | $REPO_ROOT/README.working-tree.md | ALLOW | dir_exists | N/A | N/A |
| Write | **/.env* | DENY | N/A | N/A | ABORT "Secrets file" |
| Read | $REPO_ROOT/.ai-context.json | ALLOW | file_exists | N/A | N/A |

SECURITY CONSTRAINTS:
- Can only write to current worktree directory (REPO_ROOT)
- Cannot modify files outside current worktree
- Cannot execute destructive operations
- All file writes must be to metadata files only

## TEST CASES

### TC001: Adopt worktree without metadata

PRECONDITIONS:
- In git repository at /Users/dev/myapp
- Current branch: feature/login
- File does NOT exist: /Users/dev/myapp/.ai-context.json

INPUT:
```
/adopt:working-tree
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → REPO_ROOT="/Users/dev/myapp", WORKTREE_NAME="myapp", CURRENT_BRANCH="feature/login"
2. STEP 2 → EXISTS=1 (no metadata)
3. STEP 4 → MODE_ARG="", DESCRIPTION=""
4. STEP 5 → MODE="feature" (inferred from "feature/" prefix)
5. STEP 6 → Generate timestamp
6. STEP 7 → Write .ai-context.json
7. STEP 8 → README_EXISTS=1, create README
8. STEP 9 → Output summary

EXPECTED OUTPUT:
```
Adopted worktree successfully!

  Directory: myapp
  Branch: feature/login
  Mode: feature
  Description: None

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md (created)

Use /status:working-tree to view metadata anytime.
```

VALIDATION COMMANDS:
```bash
# Verify .ai-context.json created
test -f /Users/dev/myapp/.ai-context.json && echo "PASS" || echo "FAIL"
jq -r '.mode' /Users/dev/myapp/.ai-context.json | grep "feature" && echo "PASS" || echo "FAIL"

# Verify README created
test -f /Users/dev/myapp/README.working-tree.md && echo "PASS" || echo "FAIL"
```

### TC002: Adopt with explicit mode and description

PRECONDITIONS:
- In git repository at /Users/dev/myapp
- Current branch: main
- No existing metadata

INPUT:
```
/adopt:working-tree --mode main --description "Primary development branch"
```

EXPECTED EXECUTION FLOW:
1-2. Standard detection
3. STEP 4 → MODE_ARG="main", DESCRIPTION="Primary development branch"
4. STEP 5 → MODE="main" (explicit, not inferred)
5-8. Standard flow

EXPECTED .ai-context.json:
```json
{
  "worktree": "myapp",
  "branch": "main",
  "mode": "main",
  "created": "2025-11-23T12:34:56Z",
  "description": "Primary development branch"
}
```

VALIDATION:
```bash
jq -r '.mode' .ai-context.json | grep "main" && echo "PASS" || echo "FAIL"
jq -r '.description' .ai-context.json | grep "Primary development branch" && echo "PASS" || echo "FAIL"
```

### TC003: Metadata already exists - user keeps existing

PRECONDITIONS:
- In git repository at /Users/dev/myapp
- File exists: /Users/dev/myapp/.ai-context.json with valid data

INPUT:
```
/adopt:working-tree --mode experiment
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → Detect repo
2. STEP 2 → EXISTS=0 (metadata exists)
3. STEP 3 → Display existing metadata, ask user
4. USER SELECTS "Keep existing metadata"
5. TERMINATE (no changes)

EXPECTED OUTPUT:
```
Current worktree already has metadata:

  Directory:    myapp
  Branch:       feature/login
  Mode:         feature
  Created:      2025-11-20T10:00:00Z
  Description:  Original description

Do you want to overwrite this metadata?
```

POSTCONDITIONS:
- .ai-context.json unchanged
- No files modified

### TC004: Metadata already exists - user overwrites

PRECONDITIONS:
- In git repository with existing .ai-context.json

INPUT:
```
/adopt:working-tree --mode experiment --description "New description"
```

EXPECTED EXECUTION FLOW:
1-2. Detect repo, metadata exists
3. STEP 3 → Display existing, ask user
4. USER SELECTS "Overwrite with new metadata"
5-9. Continue with creation (new timestamp, new mode, new description)

EXPECTED OUTPUT:
```
Current worktree already has metadata:
  [existing data shown]

Do you want to overwrite this metadata?

[User confirms overwrite]

Adopted worktree successfully!

  Directory: myapp
  Branch: feature/login
  Mode: experiment
  Description: New description

Metadata files created:
  ✓ .ai-context.json
  - README.working-tree.md (already exists)

Use /status:working-tree to view metadata anytime.
```

### TC005: README already exists

PRECONDITIONS:
- No .ai-context.json
- README.working-tree.md already exists

INPUT:
```
/adopt:working-tree
```

EXPECTED EXECUTION FLOW:
1-7. Standard flow, create .ai-context.json
8. STEP 8 → README_EXISTS=0 (exists), skip creation
9. STEP 9 → Output shows README skipped

EXPECTED OUTPUT:
```
Adopted worktree successfully!

  Directory: myapp
  Branch: feature/login
  Mode: feature
  Description: None

Metadata files created:
  ✓ .ai-context.json
  - README.working-tree.md (already exists)

Use /status:working-tree to view metadata anytime.
```

## USE CASES

### UC001: Adopting main repository
When working in main repo without worktrees:
```bash
cd ~/myapp
/adopt:working-tree --mode main --description "Primary development branch"
```

### UC002: Adopting manually created worktree
If worktree created without /create:working-tree:
```bash
cd ../myapp-feature-something
/adopt:working-tree
```

### UC003: Adding description later
If worktree created without description:
```bash
/adopt:working-tree --description "Working on user authentication refactor"
```
(Will prompt to overwrite existing metadata)

### UC004: Correcting mode
If mode was inferred incorrectly:
```bash
/adopt:working-tree --mode experiment
```
(Will prompt to overwrite existing metadata)

## RELATED COMMANDS

- /status:working-tree - View current metadata after adoption
- /create:working-tree - Create new worktree with metadata from start
- /list:working-tree - See all worktrees and their metadata status

## DELEGATION

For organizing worktree adoption strategy:
```
Task(
  subagent_type='working-tree-consultant',
  description='Worktree adoption strategy',
  prompt='[question about when/how to adopt worktrees]'
)
```

---
description: Create a new git worktree with branch and .ai-context.json metadata
argument-hint: <branch-name> [--mode <mode>] [--description "<text>"]
allowed-tools: Bash, Write, Read
model: sonnet
---

# /working-tree:new

Create new branch (if needed), attach git worktree, generate AI metadata files for isolated development.

## ARGUMENT SPECIFICATION

```
SYNTAX: /working-tree:new <branch-name> [--mode <mode>] [--description "<text>"]

REQUIRED:
  <branch-name>
    Type: string
    Position: 1
    Validation: ^[a-zA-Z0-9/_-]+$
    Examples: "feature/login", "bugfix/timeout", "main"

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
REPO_NAME=$(basename "$REPO_ROOT")
PARENT_DIR=$(dirname "$REPO_ROOT")
```

NEXT:
- On success → STEP 2
- On failure → ABORT

### STEP 2: PARSE AND VALIDATE ARGUMENTS

PARSE:
```bash
# Extract branch name (first positional argument)
BRANCH_NAME="$1"

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
- IF BRANCH_NAME is empty → ERROR PATTERN "missing-branch-name"
- IF BRANCH_NAME !~ ^[a-zA-Z0-9/_-]+$ → ERROR PATTERN "invalid-branch-name"
- IF MODE_ARG not empty AND MODE_ARG not in [main, feature, bugfix, experiment, review] → ERROR PATTERN "invalid-mode"

NEXT:
- On success → STEP 3
- On failure → ABORT

### STEP 3: DETERMINE MODE

EXECUTE:
```bash
if [ -n "$MODE_ARG" ]; then
    # Explicit mode provided
    MODE="$MODE_ARG"
else
    # Infer from branch name using MODE_INFERENCE_ALGORITHM
    case "$BRANCH_NAME" in
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
- On success → STEP 4
- On failure → ABORT (should not occur if STEP 2 validation passed)

### STEP 4: CHECK BRANCH EXISTENCE

EXECUTE:
```bash
git show-ref --verify --quiet refs/heads/$BRANCH_NAME
BRANCH_EXISTS=$?
```

BRANCH_EXISTS values:
- 0 = branch exists
- 1 = branch does not exist
- Other = error

VALIDATION:
- IF BRANCH_EXISTS not in [0, 1] → ERROR PATTERN "git-command-failed"

ACTION:
- IF BRANCH_EXISTS == 1 (does not exist) → Create branch in STEP 5
- IF BRANCH_EXISTS == 0 (exists) → Use existing branch, skip to STEP 6

NEXT:
- On BRANCH_EXISTS == 0 → STEP 6
- On BRANCH_EXISTS == 1 → STEP 5
- On error → ABORT

### STEP 5: CREATE NEW BRANCH

EXECUTE (only if BRANCH_EXISTS == 1):
```bash
git branch "$BRANCH_NAME" 2>&1
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "branch-creation-failed"

NEXT:
- On success → STEP 6
- On failure → ABORT

### STEP 6: DERIVE WORKTREE DIRECTORY NAME

EXECUTE:
```bash
# Normalize branch name: replace / and _ with -, convert to lowercase
NORMALIZED_BRANCH=$(echo "$BRANCH_NAME" | tr '/_' '-' | tr '[:upper:]' '[:lower:]')
WORKTREE_NAME="${REPO_NAME}-${NORMALIZED_BRANCH}"
WORKTREE_PATH="${PARENT_DIR}/${WORKTREE_NAME}"
```

NORMALIZATION RULES:
- Replace `/` with `-`
- Replace `_` with `-`
- Convert to lowercase

EXAMPLES:
- myapp + feature/login → myapp-feature-login
- api-server + bugfix/SESSION_timeout → api-server-bugfix-session-timeout

DATA:
- WORKTREE_NAME = derived directory name
- WORKTREE_PATH = absolute path to worktree location

NEXT:
- On success → STEP 7
- No validation needed (pure transformation)

### STEP 7: CHECK FOR EXISTING WORKTREE ON BRANCH

EXECUTE:
```bash
EXISTING_WORKTREE=$(git worktree list --porcelain | grep -A 3 "^branch refs/heads/$BRANCH_NAME$" | grep "^worktree " | cut -d' ' -f2)
```

VALIDATION:
- IF EXISTING_WORKTREE not empty → ERROR PATTERN "branch-has-worktree" with path=$EXISTING_WORKTREE

NEXT:
- On EXISTING_WORKTREE empty → STEP 8
- On EXISTING_WORKTREE not empty → ABORT

### STEP 8: CHECK TARGET DIRECTORY DOESN'T EXIST

EXECUTE:
```bash
test -e "$WORKTREE_PATH"
DIR_EXISTS=$?
```

VALIDATION:
- IF DIR_EXISTS == 0 (directory exists) → ERROR PATTERN "directory-exists"

NEXT:
- On DIR_EXISTS != 0 (does not exist) → STEP 9
- On DIR_EXISTS == 0 (exists) → ABORT

### STEP 9: CREATE WORKTREE

EXECUTE:
```bash
git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>&1
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "worktree-creation-failed"

NEXT:
- On success → STEP 10
- On failure → ABORT

### STEP 10: GENERATE TIMESTAMP

EXECUTE:
```bash
CREATED_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

FORMAT: ISO 8601 UTC (example: 2025-11-23T12:34:56Z)

VALIDATION:
- CREATED_TIMESTAMP must match pattern: ^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$

NEXT:
- On success → STEP 11
- No failure case

### STEP 11: GENERATE .ai-context.json

CONTENT TEMPLATE:
```json
{
  "worktree": "{WORKTREE_NAME}",
  "branch": "{BRANCH_NAME}",
  "mode": "{MODE}",
  "created": "{CREATED_TIMESTAMP}",
  "description": "{DESCRIPTION}"
}
```

SUBSTITUTIONS:
- {WORKTREE_NAME} = from STEP 6
- {BRANCH_NAME} = from STEP 2
- {MODE} = from STEP 3
- {CREATED_TIMESTAMP} = from STEP 10
- {DESCRIPTION} = from STEP 2 (empty string if not provided)

EXECUTE:
```bash
cat > "$WORKTREE_PATH/.ai-context.json" <<EOF
{
  "worktree": "$WORKTREE_NAME",
  "branch": "$BRANCH_NAME",
  "mode": "$MODE",
  "created": "$CREATED_TIMESTAMP",
  "description": "$DESCRIPTION"
}
EOF
```

VALIDATION:
- File must be created at exact path: $WORKTREE_PATH/.ai-context.json
- File must contain valid JSON
- Verify with: `jq empty "$WORKTREE_PATH/.ai-context.json"`
- IF jq fails → ERROR PATTERN "metadata-write-failed"

NEXT:
- On success → STEP 12
- On failure → ABORT (and cleanup worktree)

### STEP 12: GENERATE README.working-tree.md

CONTENT TEMPLATE:
```markdown
# Worktree: {WORKTREE_NAME}

**Branch:** `{BRANCH_NAME}`
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
- Worktree path: {WORKTREE_PATH}
- Branch: {BRANCH_NAME}

See `.ai-context.json` for machine-readable metadata.
```

SUBSTITUTIONS:
- {WORKTREE_NAME} = from STEP 6
- {BRANCH_NAME} = from STEP 2
- {MODE} = from STEP 3
- {CREATED_TIMESTAMP} = from STEP 10
- {DESCRIPTION_OR_DEFAULT} = DESCRIPTION if not empty, else "No description provided"
- {REPO_ROOT} = from STEP 1
- {WORKTREE_PATH} = from STEP 6

EXECUTE:
```bash
DESCRIPTION_TEXT="${DESCRIPTION:-No description provided}"
cat > "$WORKTREE_PATH/README.working-tree.md" <<EOF
# Worktree: $WORKTREE_NAME

**Branch:** \`$BRANCH_NAME\`
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
- Worktree path: $WORKTREE_PATH
- Branch: $BRANCH_NAME

See \`.ai-context.json\` for machine-readable metadata.
EOF
```

VALIDATION:
- File must exist at: $WORKTREE_PATH/README.working-tree.md
- IF file creation failed → ERROR PATTERN "readme-write-failed"

NEXT:
- On success → STEP 13
- On failure → ABORT (and cleanup)

### STEP 13: OUTPUT SUCCESS SUMMARY

OUTPUT FORMAT (exact):
```
Created worktree successfully!

  Path: {WORKTREE_PATH}
  Branch: {BRANCH_NAME}
  Mode: {MODE}
  Description: {DESCRIPTION_OR_NONE}

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md

To switch to this worktree:
  cd {WORKTREE_PATH}
```

SUBSTITUTIONS:
- {WORKTREE_PATH} = from STEP 6
- {BRANCH_NAME} = from STEP 2
- {MODE} = from STEP 3
- {DESCRIPTION_OR_NONE} = DESCRIPTION if not empty, else "None"

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
- CLEANUP: none needed
- RETRY: false

### PATTERN: missing-branch-name

DETECTION:
- TRIGGER: BRANCH_NAME is empty string after parsing

RESPONSE (exact):
```
Error: Missing required argument <branch-name>

Usage:
  /working-tree:new <branch-name> [--mode <mode>] [--description "<text>"]

Example:
  /working-tree:new feature/my-feature
```

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: invalid-branch-name

DETECTION:
- TRIGGER: BRANCH_NAME does not match ^[a-zA-Z0-9/_-]+$
- INDICATORS: Contains invalid characters

RESPONSE (exact):
```
Error: Invalid branch name '{BRANCH_NAME}'

Branch names must contain only:
  - Letters (a-z, A-Z)
  - Numbers (0-9)
  - Forward slashes (/)
  - Hyphens (-)
  - Underscores (_)

Example valid names:
  feature/login
  bugfix/timeout-issue
  exp/ai_integration
```

TEMPLATE SUBSTITUTIONS:
- {BRANCH_NAME} = the invalid branch name provided

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
  /working-tree:new my-branch --mode feature
```

TEMPLATE SUBSTITUTIONS:
- {MODE_ARG} = the invalid mode provided

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: git-command-failed

DETECTION:
- TRIGGER: Any git command (except specific patterns) returns non-zero exit code
- CAPTURE: stderr from git command

RESPONSE (exact):
```
Error: Git command failed

Git error: {GIT_STDERR}

Check that:
  - You're in a git repository
  - Git is installed and working
  - You have necessary permissions
```

TEMPLATE SUBSTITUTIONS:
- {GIT_STDERR} = captured stderr

CONTROL FLOW:
- ABORT: true
- CLEANUP: Remove worktree if created
- RETRY: false

### PATTERN: branch-creation-failed

DETECTION:
- TRIGGER: git branch command fails (STEP 5)
- CAPTURE: stderr from git branch

RESPONSE (exact):
```
Error: Failed to create branch '{BRANCH_NAME}'

Git error: {GIT_STDERR}

Check that:
  - Branch name is valid
  - You're not in detached HEAD state
  - You have permission to create branches
```

TEMPLATE SUBSTITUTIONS:
- {BRANCH_NAME} = attempted branch name
- {GIT_STDERR} = captured stderr

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: branch-has-worktree

DETECTION:
- TRIGGER: git worktree list shows branch already has attached worktree (STEP 7)
- CAPTURE: EXISTING_WORKTREE path

RESPONSE (exact):
```
Error: Branch '{BRANCH_NAME}' already has a worktree at {EXISTING_WORKTREE}

Use one of:
  - /working-tree:list to see all worktrees
  - cd {EXISTING_WORKTREE} to use the existing worktree
  - /working-tree:destroy {EXISTING_WORKTREE} to remove it first
```

TEMPLATE SUBSTITUTIONS:
- {BRANCH_NAME} = branch with existing worktree
- {EXISTING_WORKTREE} = path to existing worktree

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: directory-exists

DETECTION:
- TRIGGER: Target directory already exists (STEP 8)
- CHECK: test -e "$WORKTREE_PATH" returns 0

RESPONSE (exact):
```
Error: Directory '{WORKTREE_PATH}' already exists

Choose a different branch name or remove the existing directory.

To remove:
  rm -rf {WORKTREE_PATH}

(Be careful - this will delete all contents)
```

TEMPLATE SUBSTITUTIONS:
- {WORKTREE_PATH} = path that already exists

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: worktree-creation-failed

DETECTION:
- TRIGGER: git worktree add fails (STEP 9)
- CAPTURE: stderr from git worktree add

RESPONSE (exact):
```
Error: Failed to create worktree

Git error: {GIT_STDERR}

Check that:
  - Parent directory is writable
  - Branch name is valid
  - No permission issues
```

TEMPLATE SUBSTITUTIONS:
- {GIT_STDERR} = captured stderr

CONTROL FLOW:
- ABORT: true
- CLEANUP: Attempt to remove partially created worktree
- RETRY: false

### PATTERN: metadata-write-failed

DETECTION:
- TRIGGER: .ai-context.json write fails or invalid JSON (STEP 11)
- CHECK: jq validation fails

RESPONSE (exact):
```
Error: Failed to write .ai-context.json

The worktree was created but metadata file generation failed.

Worktree location: {WORKTREE_PATH}

You can:
  1. Manually create .ai-context.json
  2. Use /working-tree:adopt to regenerate metadata
  3. Remove worktree with /working-tree:destroy {WORKTREE_PATH}
```

TEMPLATE SUBSTITUTIONS:
- {WORKTREE_PATH} = worktree path

CONTROL FLOW:
- ABORT: false (worktree exists, metadata failed)
- CLEANUP: none (leave worktree intact)
- FALLBACK: User can manually fix or adopt

### PATTERN: readme-write-failed

DETECTION:
- TRIGGER: README.working-tree.md write fails (STEP 12)

RESPONSE (exact):
```
Warning: Failed to write README.working-tree.md

The worktree and .ai-context.json were created successfully.

Worktree location: {WORKTREE_PATH}

You can manually create the README if needed.
```

TEMPLATE SUBSTITUTIONS:
- {WORKTREE_PATH} = worktree path

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
| Bash | dirname:* | ALLOW | N/A | N/A | N/A |
| Bash | tr:* | ALLOW | N/A | N/A | N/A |
| Bash | grep:* | ALLOW | N/A | N/A | N/A |
| Bash | cat > *.json | ALLOW | parent_dir_writable | valid_json | N/A |
| Bash | cat > *.md | ALLOW | parent_dir_writable | N/A | N/A |
| Bash | jq:* | ALLOW | N/A | N/A | N/A |
| Bash | rm -rf:* | DENY | N/A | N/A | ABORT "Destructive operation not allowed" |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Write | $WORKTREE_PATH/.ai-context.json | ALLOW | dir_exists | valid_json | N/A |
| Write | $WORKTREE_PATH/README.working-tree.md | ALLOW | dir_exists | N/A | N/A |
| Write | **/.env* | DENY | N/A | N/A | ABORT "Secrets file" |
| Read | * | DENY | N/A | N/A | ABORT "Command is write-only" |

SECURITY CONSTRAINTS:
- Can only write to newly created worktree directory
- Cannot modify existing files
- Cannot remove directories (even on cleanup)
- Git worktree add is safe (git manages cleanup)

## TEST CASES

### TC001: Create new feature branch worktree

PRECONDITIONS:
- In git repository at /Users/dev/myapp
- Current branch: main
- Branch "feature/login-refactor" does not exist
- Directory /Users/dev/myapp-feature-login-refactor does not exist

INPUT:
```
/working-tree:new feature/login-refactor
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → REPO_ROOT="/Users/dev/myapp", REPO_NAME="myapp", PARENT_DIR="/Users/dev"
2. STEP 2 → BRANCH_NAME="feature/login-refactor", MODE_ARG="", DESCRIPTION=""
3. STEP 3 → MODE="feature" (inferred from "feature/" prefix)
4. STEP 4 → BRANCH_EXISTS=1 (does not exist)
5. STEP 5 → Create branch "feature/login-refactor"
6. STEP 6 → WORKTREE_NAME="myapp-feature-login-refactor", WORKTREE_PATH="/Users/dev/myapp-feature-login-refactor"
7. STEP 7 → No existing worktree
8. STEP 8 → Directory does not exist
9. STEP 9 → Create worktree
10. STEP 10 → Generate timestamp
11. STEP 11 → Write .ai-context.json
12. STEP 12 → Write README.working-tree.md
13. STEP 13 → Output summary

EXPECTED OUTPUT:
```
Created worktree successfully!

  Path: /Users/dev/myapp-feature-login-refactor
  Branch: feature/login-refactor
  Mode: feature
  Description: None

Metadata files created:
  ✓ .ai-context.json
  ✓ README.working-tree.md

To switch to this worktree:
  cd /Users/dev/myapp-feature-login-refactor
```

VALIDATION COMMANDS:
```bash
# Verify worktree created
test -d /Users/dev/myapp-feature-login-refactor && echo "PASS" || echo "FAIL"

# Verify branch created
git show-ref --verify refs/heads/feature/login-refactor && echo "PASS" || echo "FAIL"

# Verify .ai-context.json
test -f /Users/dev/myapp-feature-login-refactor/.ai-context.json && echo "PASS" || echo "FAIL"
jq -r '.mode' /Users/dev/myapp-feature-login-refactor/.ai-context.json | grep "feature" && echo "PASS" || echo "FAIL"

# Verify README
test -f /Users/dev/myapp-feature-login-refactor/README.working-tree.md && echo "PASS" || echo "FAIL"
```

### TC002: Create with explicit mode and description

PRECONDITIONS:
- In git repository at /Users/dev/myapp
- Branch "my-experiment" does not exist

INPUT:
```
/working-tree:new my-experiment --mode experiment --description "Testing new architecture"
```

EXPECTED EXECUTION FLOW:
1-2. Parse arguments → BRANCH_NAME="my-experiment", MODE_ARG="experiment", DESCRIPTION="Testing new architecture"
3. STEP 3 → MODE="experiment" (explicit, not inferred)
4-13. Standard flow

EXPECTED .ai-context.json:
```json
{
  "worktree": "myapp-my-experiment",
  "branch": "my-experiment",
  "mode": "experiment",
  "created": "2025-11-23T12:34:56Z",
  "description": "Testing new architecture"
}
```

VALIDATION:
```bash
jq -r '.mode' .ai-context.json | grep "experiment" && echo "PASS" || echo "FAIL"
jq -r '.description' .ai-context.json | grep "Testing new architecture" && echo "PASS" || echo "FAIL"
```

### TC003: Branch already has worktree

PRECONDITIONS:
- Branch "feature/existing" already has worktree at /Users/dev/myapp-feature-existing

INPUT:
```
/working-tree:new feature/existing
```

EXPECTED EXECUTION FLOW:
1-6. Standard detection and parsing
7. STEP 7 → EXISTING_WORKTREE="/Users/dev/myapp-feature-existing"
8. ERROR PATTERN "branch-has-worktree"
9. ABORT

EXPECTED OUTPUT:
```
Error: Branch 'feature/existing' already has a worktree at /Users/dev/myapp-feature-existing

Use one of:
  - /working-tree:list to see all worktrees
  - cd /Users/dev/myapp-feature-existing to use the existing worktree
  - /working-tree:destroy /Users/dev/myapp-feature-existing to remove it first
```

POSTCONDITIONS:
- No new worktree created
- No new branch created
- Existing worktree unchanged

### TC004: Invalid mode specified

PRECONDITIONS:
- In git repository

INPUT:
```
/working-tree:new test-branch --mode production
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → Detect repo
2. STEP 2 → MODE_ARG="production"
3. Validation fails: "production" not in [main, feature, bugfix, experiment, review]
4. ERROR PATTERN "invalid-mode"
5. ABORT

EXPECTED OUTPUT:
```
Error: Invalid mode 'production'

Valid modes: main, feature, bugfix, experiment, review

Example:
  /working-tree:new my-branch --mode feature
```

### TC005: Directory already exists

PRECONDITIONS:
- Directory /Users/dev/myapp-feature-test already exists (not a worktree)

INPUT:
```
/working-tree:new feature/test
```

EXPECTED EXECUTION FLOW:
1-7. Standard flow
8. STEP 8 → DIR_EXISTS=0 (directory exists)
9. ERROR PATTERN "directory-exists"
10. ABORT

EXPECTED OUTPUT:
```
Error: Directory '/Users/dev/myapp-feature-test' already exists

Choose a different branch name or remove the existing directory.

To remove:
  rm -rf /Users/dev/myapp-feature-test

(Be careful - this will delete all contents)
```

## RELATED COMMANDS

- /working-tree:status - Show current worktree metadata
- /working-tree:list - List all worktrees with metadata
- /working-tree:adopt - Add metadata to existing worktree
- /working-tree:destroy - Remove worktree safely

## DELEGATION

For complex worktree strategy or organization questions:
```
Task(
  subagent_type='working-tree-consultant',
  description='Worktree strategy consultation',
  prompt='[question about worktree organization, naming, or workflow]'
)
```

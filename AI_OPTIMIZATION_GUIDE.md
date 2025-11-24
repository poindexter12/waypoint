# AI Optimization Guide for Claude Code Components

**Version**: 1.0.0
**Created**: 2025-11-24
**Purpose**: Document the methodology for optimizing agents, commands, and skills for AI consumption

## Philosophy

This guide documents the transformation from human-readable documentation to AI-optimized specifications. The goal is to create deterministic, machine-parseable components that enable consistent, reliable AI behavior.

### Core Principles

1. **Explicit Over Implicit**: Every decision point, validation rule, and error condition must be explicitly stated
2. **Deterministic Behavior**: Use algorithms, decision trees, and sequential protocols instead of narrative descriptions
3. **Machine-Parseable**: Structure information for programmatic interpretation, not human reading
4. **Safety First**: Explicit tool permissions, pre/post checks, and error handling
5. **Testable**: Concrete test cases with validation commands for every scenario

## The Five Core Patterns

Every optimized component should implement these patterns where applicable:

### 1. EXECUTION PROTOCOL

Sequential steps with explicit control flow.

**Structure**:
```markdown
### STEP N: {ACTION}

EXECUTE:
```bash
{command or pseudocode}
```

VALIDATION:
- IF condition → ERROR PATTERN "name"
- Check constraints

NEXT:
- On success → STEP M
- On failure → ABORT/RETRY
```

**Key Elements**:
- **EXECUTE**: Exact commands or deterministic algorithms (Python/bash pseudocode)
- **VALIDATION**: Explicit checks with conditions and error pattern references
- **NEXT**: Explicit control flow to next step or error handling

**Example** (from `/status:working-tree`):
```markdown
### STEP 1: GET CURRENT DIRECTORY

EXECUTE:
```bash
CURRENT_DIR=$(git rev-parse --show-toplevel 2>&1)
EXIT_CODE=$?
```

VALIDATION:
- IF EXIT_CODE != 0 → ERROR PATTERN "not-in-git-repo"

NEXT:
- On success → STEP 2
- On failure → ABORT
```

### 2. ERROR PATTERNS

Machine-parseable error detection and response.

**Structure**:
```markdown
### PATTERN: error-name

DETECTION:
- TRIGGER: {exact condition that triggers this error}
- INDICATORS: {additional signals}
- CHECK: {validation command if applicable}

RESPONSE (exact):
```
{Exact error message text}
{Formatted with specific structure}
```

TEMPLATE SUBSTITUTIONS:
- {VAR_NAME} = description

CONTROL FLOW:
- ABORT: true/false
- CLEANUP: {actions to take}
- RETRY: {retry conditions}
```

**Key Elements**:
- **DETECTION**: Exact trigger conditions with validation checks
- **RESPONSE**: Exact error message with template variables
- **CONTROL FLOW**: Explicit abort/cleanup/retry behavior

**Example** (from `/create:working-tree`):
```markdown
### PATTERN: invalid-branch-name

DETECTION:
- TRIGGER: Branch name contains invalid characters
- CHECK: `[[ "$BRANCH_NAME" =~ ^[a-zA-Z0-9/_-]+$ ]]` returns false

RESPONSE (exact):
```
Error: Invalid branch name "{BRANCH_NAME}"

Branch names must:
  - Contain only letters, numbers, hyphens, slashes, underscores
  - Not start or end with /
  - Not contain consecutive slashes or ..

Examples:
  ✓ feature/new-login
  ✓ bugfix/auth-error
  ✗ feature//double-slash
  ✗ ../escape-attempt
```

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: Ask user for valid branch name
```

### 3. TOOL PERMISSION MATRIX

Explicit security constraints for tool usage.

**Structure**:
```markdown
| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| {Tool} | {pattern} | ALLOW/DENY | {check} | {check} | {action} |
```

**Key Elements**:
- **Tool**: Specific tool name (Bash, Read, Write, Edit, etc.)
- **Pattern**: Specific pattern or wildcard (git:*, *.md, etc.)
- **Permission**: ALLOW or DENY
- **Pre-Check**: Validation before execution
- **Post-Check**: Verification after execution
- **On-Deny-Action**: What happens if permission denied

**Example** (from `/destroy:working-tree`):
```markdown
| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| Bash | git worktree:* | ALLOW | worktree_exists | N/A | N/A |
| Bash | rm -rf:* | DENY | N/A | N/A | ABORT "Unsafe deletion" |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Read | .ai-context.json | ALLOW | file_exists | N/A | N/A |
| Write | * | DENY | N/A | N/A | ABORT "Destroy is read-only except cleanup" |
```

**Security Constraints Section**:
Always follow the table with explicit security constraints:
```markdown
SECURITY CONSTRAINTS:
- {Constraint 1}
- {Constraint 2}
- {Rationale for DENY patterns}
```

### 4. TEST CASES

Concrete scenarios with validation commands.

**Structure**:
```markdown
### TC{ID}: {Test Name}

PRECONDITIONS:
- {System state requirements}
- {File/directory setup}

INPUT:
```
{Exact command with arguments}
```

EXPECTED EXECUTION FLOW:
1. STEP X → {what happens}
2. STEP Y → {what happens}
...

EXPECTED OUTPUT:
```
{Exact expected output}
```

VALIDATION COMMANDS:
```bash
# Commands to verify behavior
test condition && echo "PASS" || echo "FAIL"
```

POSTCONDITIONS:
- {Final system state}
- {Files created/modified/deleted}
```

**Required Test Cases**:
1. **Happy path**: Typical successful usage
2. **With optional arguments**: All optional parameters used
3. **Missing required argument**: Error handling
4. **Invalid argument**: Validation and error messages
5. **Edge case**: Boundary conditions
6. **Security/safety**: Permission checks and safety validations

**Example** (from `/adopt:working-tree`):
```markdown
### TC003: Adopt with existing metadata (overwrite)

PRECONDITIONS:
- In git repository /Users/dev/myapp
- File exists: /Users/dev/myapp/.ai-context.json
- Contains: {"mode": "main", "description": "old description"}

INPUT:
```
/adopt:working-tree --mode feature --description "New feature branch"
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → Verify in git repo ✓
2. STEP 2 → Check for existing metadata (found)
3. STEP 3 → Prompt user: "Metadata already exists. Overwrite? (y/n)"
4. User: y
5. STEP 4 → Infer mode (provided via flag: feature)
6. STEP 5-7 → Write new metadata, verify, display

EXPECTED OUTPUT:
```
Metadata file already exists at /Users/dev/myapp/.ai-context.json
Current content:
{
  "mode": "main",
  "description": "old description"
}

Overwrite with new metadata? (y/n): y

✓ Working tree metadata added

  Path: /Users/dev/myapp
  Mode: feature
  Description: New feature branch

Metadata written to: /Users/dev/myapp/.ai-context.json
```

VALIDATION COMMANDS:
```bash
cat /Users/dev/myapp/.ai-context.json | jq -e '.mode == "feature"'
cat /Users/dev/myapp/.ai-context.json | jq -e '.description == "New feature branch"'
```

POSTCONDITIONS:
- .ai-context.json exists with new values
- Old metadata overwritten
```

### 5. INVOCATION DECISION TREE

For agents only: Multi-phase pattern matching with scoring.

**Structure**:
```markdown
## INVOCATION DECISION TREE

```
INPUT: user_message

PHASE 1: Explicit {Pattern Name}
  IF user_message matches "{regex}" → INVOKE
  IF user_message matches "{regex}" → INVOKE
  CONTINUE to PHASE 2

PHASE 2: Anti-Pattern Detection
  IF user_message matches "{wrong pattern}" → DO_NOT_INVOKE (wrong specialist)
  IF user_message matches "{trivial pattern}" → DO_NOT_INVOKE (trivial task)
  CONTINUE to PHASE 3

PHASE 3: Pattern Matching with Scoring
  SCORE = 0.0

  IF user_message {condition} → SCORE += {value}
  IF user_message {condition} → SCORE += {value}
  ...

  CONTINUE to PHASE 4

PHASE 4: Decision with Confidence Threshold
  IF SCORE >= {high_threshold} → INVOKE
  IF SCORE >= {medium_threshold} AND SCORE < {high_threshold} → ASK_CLARIFICATION
  IF SCORE < {medium_threshold} → DO_NOT_INVOKE
```
```

**Key Elements**:
- **PHASE 1**: Explicit pattern matches that immediately invoke (high confidence)
- **PHASE 2**: Anti-patterns that should never invoke (wrong tool for job)
- **PHASE 3**: Scoring algorithm with weighted pattern matches
- **PHASE 4**: Threshold-based decision making

**Example** (from `claire-author-agent`):
```markdown
## INVOCATION DECISION TREE

```
INPUT: user_message

PHASE 1: Explicit Agent Operations
  IF user_message matches "create (an? )?agent" → INVOKE
  IF user_message matches "(optimize|improve|fix) .* agent" → INVOKE
  IF user_message matches "agent (design|structure)" → INVOKE
  CONTINUE to PHASE 2

PHASE 2: Anti-Pattern Detection
  IF user_message matches "create (a )?(command|skill)" → DO_NOT_INVOKE (wrong specialist)
  IF user_message matches "fix.*typo|spelling" AND NOT "agent" → DO_NOT_INVOKE (trivial edit)
  CONTINUE to PHASE 3

PHASE 3: Pattern Matching with Scoring
  SCORE = 0.0

  IF user_message contains_any ["new agent", "agent creation", "build agent"] → SCORE += 0.4
  IF user_message matches "how (do I|to) (create|make) .* agent" → SCORE += 0.3
  IF user_message contains "agent" AND "behavior" → SCORE += 0.2
  IF user_message contains "system prompt" → SCORE += 0.15

  CONTINUE to PHASE 4

PHASE 4: Decision with Confidence Threshold
  IF SCORE >= 0.65 → INVOKE
  IF SCORE >= 0.35 AND SCORE < 0.65 → ASK_CLARIFICATION
  IF SCORE < 0.35 → DO_NOT_INVOKE
```
```

## Naming Conventions

### Commands: /verb:namespace

Commands use the format `/verb:namespace` where:
- **verb**: Action word (create, list, destroy, fetch, adopt, status)
- **namespace**: Topic/domain (working-tree, claire, git, etc.)

**Examples**:
- ✓ `/create:working-tree`
- ✓ `/list:working-tree`
- ✓ `/fetch:docs-claire`
- ✓ `/status:working-tree`
- ✗ `/wtm-new` (old pattern)
- ✗ `/createWorktree` (camelCase)
- ✗ `/create_worktree` (underscores)

**File naming**: `{namespace}/commands/{verb}.md`
- `/create:working-tree` → `working-tree/commands/create.md`
- `/list:working-tree` → `working-tree/commands/list.md`
- `/fetch:docs-claire` → `claire/commands/fetch-docs.md`

### Agents: namespace-verb-noun

Agents use the format `namespace-verb-noun` where:
- **namespace**: Topic/domain (working-tree, claire)
- **verb-noun**: Action-target pattern (author-agent, author-command, author-skill)

**Examples**:
- ✓ `claire-author-agent`
- ✓ `claire-author-command`
- ✓ `claire-author-skill`
- ✓ `working-tree-consultant`
- ✗ `claire-agent-author` (wrong order)
- ✗ `agentAuthor` (camelCase)

**File naming**: `{namespace}/agents/{verb-noun}.md`
- `claire-author-agent` → `claire/agents/author-agent.md`
- `claire-author-command` → `claire/agents/author-command.md`
- `working-tree-consultant` → `working-tree/agents/consultant.md`

### Skills: namespace:skill-name

Skills use the format `namespace:skill-name` where:
- **namespace**: Topic/domain
- **skill-name**: Descriptive kebab-case name

**Directory structure**: `{namespace}/skills/{skill-name}/`
- `claire:optimization` → `claire/skills/optimization/`

## Argument Specification

### Formal Argument Schema

Commands should include a formal ARGUMENT SPECIFICATION section:

```markdown
## ARGUMENT SPECIFICATION

```
SYNTAX: /command:name <required> [optional] [--flag <value>]

REQUIRED:
  <arg-name>
    Type: string|number|path|enum{value1,value2}
    Validation: {regex or rules}
    Examples: "value1", "value2"

OPTIONAL:
  [arg-name]
    Type: type-name
    Default: default-value
    Validation: rules
    Examples: examples

FLAGS:
  [--flag-name <value>]
    Type: type-name
    Default: default-value
    Validation: rules
    Examples: examples
```
```

### Argument Patterns

- `<required>` - Required positional argument
- `[optional]` - Optional positional argument
- `[--flag]` - Optional boolean flag
- `[--flag <value>]` - Optional flag with value
- `--required-flag <value>` - Required flag with value

**Example** (from `/create:working-tree`):
```markdown
## ARGUMENT SPECIFICATION

```
SYNTAX: /create:working-tree <branch-name> [--mode <mode>] [--description "<text>"]

REQUIRED:
  <branch-name>
    Type: string
    Validation: ^[a-zA-Z0-9/_-]+$
    Examples: "feature/new-auth", "bugfix/login-error"

OPTIONAL FLAGS:
  [--mode <mode>]
    Type: enum{feature,bugfix,experiment,review}
    Default: inferred from branch name
    Validation: Must be one of allowed modes
    Examples: --mode feature, --mode bugfix

  [--description "<text>"]
    Type: string
    Default: empty string
    Validation: Any text (will be prompted if omitted)
    Examples: --description "OAuth refactor"
```
```

## Frontmatter Specifications

### Commands

```yaml
---
description: string          # REQUIRED: brief description (default: first line if omitted)
argument-hint: string        # OPTIONAL: shown during autocomplete
allowed-tools: string        # OPTIONAL: comma-separated, inherits if omitted
model: enum                  # OPTIONAL: sonnet|opus|haiku, inherits if omitted
disable-model-invocation: bool # OPTIONAL: prevent automatic invocation
---
```

**Example**:
```yaml
---
description: Create a new git worktree with branch and .ai-context.json metadata
argument-hint: <branch-name> [--mode <mode>] [--description "<text>"]
allowed-tools: Bash, Read, Write, Glob
model: sonnet
---
```

### Agents

```yaml
---
name: string                 # REQUIRED: unique identifier (lowercase, hyphens)
description: string          # REQUIRED: natural language purpose
tools: string                # OPTIONAL: comma-separated (inherits all if omitted)
model: enum                  # OPTIONAL: sonnet|opus|haiku|inherit
permissionMode: enum         # OPTIONAL: default|acceptEdits|bypassPermissions|plan|ignore
skills: string               # OPTIONAL: comma-separated skill names
---
```

**Example**:
```yaml
---
name: claire-author-agent
description: Create and optimize Claude Code agents. Agent design, architecture, behavioral tuning, validation.
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
---
```

## Deterministic Algorithms

Use Python or bash pseudocode for complex logic:

### Example 1: Mode Inference (from `/create:working-tree`)

```python
def infer_mode(branch_name: str) -> str:
    """
    Infer working tree mode from branch name.
    Returns mode string or "main" if no pattern matches.
    """
    if branch_name == "main" or branch_name == "master":
        return "main"
    elif branch_name.startswith("feature/"):
        return "feature"
    elif branch_name.startswith(("bugfix/", "fix/")):
        return "bugfix"
    elif branch_name.startswith(("experiment/", "exp/")):
        return "experiment"
    elif branch_name.startswith(("review/", "pr/")):
        return "review"
    else:
        return "main"  # default fallback
```

### Example 2: Scoring Algorithm (from `claire-coordinator`)

```python
def calculate_invocation_score(user_message: str) -> float:
    """
    Calculate confidence score for coordinator invocation.
    Range: 0.0 to 1.0
    """
    score = 0.0

    # Decision questions
    if matches(user_message, "(should I|what should I|which should I) (make|create|build|use)"):
        score += 0.35

    # Explicit coordination requests
    if contains_any(user_message, ["which agent", "which command", "which skill"]):
        score += 0.25

    # Meta questions
    if matches(user_message, "(help me )?(decide|choose|determine)"):
        score += 0.20

    # Architecture questions
    if contains_any(user_message, ["should it be", "better to", "or should"]):
        score += 0.15

    # Comparison indicators
    if matches(user_message, "(agent|command|skill).*(vs|versus|or)"):
        score += 0.10

    return min(score, 1.0)  # cap at 1.0
```

### Example 3: Parsing Algorithm (from `/list:working-tree`)

```python
def parse_worktree_list(porcelain_output: str) -> list[dict]:
    """
    Parse git worktree list --porcelain output.

    Format:
        worktree /path/to/worktree
        HEAD commit-hash
        branch refs/heads/branch-name

        worktree /another/path
        ...
    """
    worktrees = []
    current_entry = {}

    for line in porcelain_output.split("\n"):
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

    return worktrees
```

## Before/After Examples

### Example 1: Command Transformation

**BEFORE** (human-readable):
```markdown
# /wtm-new

Creates a new git worktree with a branch. You can optionally specify a mode like "feature" or "bugfix", and add a description.

## Usage

Just run the command with a branch name:
```
/wtm-new my-feature-branch
```

The command will create the worktree and set up metadata.

## Modes

- feature: For new features
- bugfix: For bug fixes
- experiment: For experimental work
```

**AFTER** (AI-optimized):
```markdown
---
description: Create a new git worktree with branch and .ai-context.json metadata
argument-hint: <branch-name> [--mode <mode>] [--description "<text>"]
allowed-tools: Bash, Read, Write, Glob
model: sonnet
---

# /create:working-tree

Create a new git worktree with associated branch and AI context metadata file.

## ARGUMENT SPECIFICATION

```
SYNTAX: /create:working-tree <branch-name> [--mode <mode>] [--description "<text>"]

REQUIRED:
  <branch-name>
    Type: string
    Validation: ^[a-zA-Z0-9/_-]+$
    Examples: "feature/new-auth", "bugfix/login-error"
...
```

## EXECUTION PROTOCOL

### STEP 1: VALIDATE BRANCH NAME

EXECUTE:
```bash
BRANCH_NAME="$1"
[[ "$BRANCH_NAME" =~ ^[a-zA-Z0-9/_-]+$ ]]
VALID=$?
```

VALIDATION:
- IF VALID != 0 → ERROR PATTERN "invalid-branch-name"

NEXT:
- On success → STEP 2
- On failure → ABORT
...

## ERROR PATTERNS

### PATTERN: invalid-branch-name

DETECTION:
- TRIGGER: Branch name contains invalid characters
- CHECK: `[[ "$BRANCH_NAME" =~ ^[a-zA-Z0-9/_-]+$ ]]` returns false
...

## TEST CASES

### TC001: Create worktree with inferred mode

PRECONDITIONS:
- In git repository /Users/dev/myapp
- Branch "feature/new-login" does not exist
...
```

### Example 2: Agent Transformation

**BEFORE** (narrative):
```markdown
# Command Author Agent

This agent helps you create new slash commands for Claude Code. It will ask you questions about what the command should do, what arguments it needs, and then generate the command file with proper formatting.

The agent knows about:
- Command naming conventions
- Frontmatter fields
- How to structure execution protocols
- Security best practices

Just invoke it when you want to create a new command!
```

**AFTER** (AI-optimized):
```markdown
---
name: claire-author-command
description: Create and optimize Claude Code slash commands. Command design, argument patterns, user experience.
tools: Read, Write, Edit, Glob, Grep
model: sonnet
---

# Claire: Author Command

Create and optimize Claude Code slash commands. Exclusive focus: command design, argument patterns, execution protocols, user experience.

## INVOCATION DECISION TREE

```
INPUT: user_message

PHASE 1: Explicit Command Operations
  IF user_message matches "create (a )?((slash )?command|/[a-z-]+)" → INVOKE
  IF user_message matches "(optimize|improve|fix) .* command" → INVOKE
  CONTINUE to PHASE 2

PHASE 2: Anti-Pattern Detection
  IF user_message matches "create (an? )?(agent|skill)" → DO_NOT_INVOKE (wrong specialist)
  CONTINUE to PHASE 3

PHASE 3: Pattern Matching with Scoring
  SCORE = 0.0
  IF user_message contains_any ["slash command", "command arguments"] → SCORE += 0.4
  CONTINUE to PHASE 4

PHASE 4: Decision with Confidence Threshold
  IF SCORE >= 0.60 → INVOKE
  IF SCORE >= 0.30 AND SCORE < 0.60 → ASK_CLARIFICATION
  IF SCORE < 0.30 → DO_NOT_INVOKE
```

## EXECUTION PROTOCOL

### STEP 1: VERIFY DOCUMENTATION CACHE

EXECUTE:
```bash
CACHE_FILE="claire/docs-cache/slash-commands.md"
test -f "$CACHE_FILE"
CACHE_EXISTS=$?
...
```
```

## Optimization Checklist

Use this checklist when optimizing any component:

### For Commands

- [ ] Rename to /verb:namespace format
- [ ] Add YAML frontmatter with required fields
- [ ] Create formal ARGUMENT SPECIFICATION section
- [ ] Add EXECUTION PROTOCOL with sequential steps
  - [ ] Each step has EXECUTE section
  - [ ] Each step has VALIDATION section
  - [ ] Each step has NEXT section with explicit control flow
- [ ] Add ERROR PATTERNS section
  - [ ] DETECTION with trigger conditions
  - [ ] RESPONSE with exact error message
  - [ ] CONTROL FLOW with abort/cleanup/retry
- [ ] Add TOOL PERMISSION MATRIX
  - [ ] All tools explicitly listed
  - [ ] ALLOW/DENY for each pattern
  - [ ] Security rationale for DENY patterns
- [ ] Add TEST CASES section
  - [ ] TC001: Happy path
  - [ ] TC002: Optional arguments
  - [ ] TC003: Error case (missing argument)
  - [ ] TC004: Error case (invalid argument)
  - [ ] TC005: Edge case
  - [ ] TC006: Security/safety case
- [ ] Add RELATED COMMANDS section
- [ ] Add DELEGATION section (when to use Task tool)

### For Agents

- [ ] Rename to namespace-verb-noun format
- [ ] Add YAML frontmatter with required fields
- [ ] Add INVOCATION DECISION TREE
  - [ ] PHASE 1: Explicit patterns
  - [ ] PHASE 2: Anti-patterns
  - [ ] PHASE 3: Scoring algorithm
  - [ ] PHASE 4: Decision thresholds
- [ ] Add EXECUTION PROTOCOL with sequential steps
- [ ] Add ERROR PATTERNS section
- [ ] Add TOOL PERMISSION MATRIX
- [ ] Add TEST SCENARIOS section
  - [ ] TS001: Standard invocation
  - [ ] TS002: Complex scenario
  - [ ] TS003: Anti-pattern (should not invoke)
  - [ ] TS004: Error handling
- [ ] Convert narrative descriptions to algorithms
- [ ] Add deterministic decision logic

### For Skills

- [ ] Rename directory to namespace/skills/skill-name/
- [ ] Create SKILL.md with frontmatter
- [ ] Add INVOCATION DECISION TREE
- [ ] Add PROGRESSIVE DISCLOSURE protocol
  - [ ] LEVEL 1: Context gathering
  - [ ] LEVEL 2: Template selection
  - [ ] LEVEL 3: Customization
  - [ ] LEVEL 4: Finalization
- [ ] Create REFERENCE.md with technical details
- [ ] Create FORMS.md with structured data collection
- [ ] Add templates/ directory with examples
- [ ] Add scripts/ directory if applicable
- [ ] Add TEST SCENARIOS

### General

- [ ] Remove narrative prose
- [ ] Replace implicit logic with explicit algorithms
- [ ] Add Python/bash pseudocode for complex logic
- [ ] Use tables for structured data
- [ ] Add validation commands to test cases
- [ ] Include exact error messages (not descriptions)
- [ ] Specify control flow explicitly
- [ ] Add security constraints
- [ ] Link related components

## Common Patterns

### Validation Pattern

```bash
COMMAND_OUTPUT=$(command 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    ERROR_PATTERN "pattern-name"
fi
```

### Confirmation Pattern

```bash
echo "Warning: {action description}"
echo -n "Continue? (y/n): "
read CONFIRMATION

if [[ "$CONFIRMATION" != "y" && "$CONFIRMATION" != "Y" ]]; then
    echo "Operation cancelled"
    exit 0
fi
```

### File Existence Check Pattern

```bash
test -f "$FILE_PATH"
FILE_EXISTS=$?

if [ $FILE_EXISTS -ne 0 ]; then
    ERROR_PATTERN "file-not-found"
fi
```

### JSON Validation Pattern

```bash
METADATA=$(cat "$FILE_PATH" 2>&1)
MODE=$(echo "$METADATA" | jq -r '.mode // "(invalid)"' 2>&1)
JQ_EXIT=$?

if [ $JQ_EXIT -ne 0 ]; then
    ERROR_PATTERN "invalid-json"
fi
```

### Git Repository Check Pattern

```bash
GIT_ROOT=$(git rev-parse --show-toplevel 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    ERROR_PATTERN "not-in-git-repo"
fi
```

## Decision Thresholds

When creating INVOCATION DECISION TREE for agents, use these guidelines for thresholds:

### Scoring Guidelines

- **0.30-0.40**: Weighted scoring values for strong indicators
- **0.10-0.20**: Weighted scoring values for weak indicators
- **0.05-0.10**: Weighted scoring values for supporting indicators

### Decision Thresholds

- **≥ 0.60-0.70**: High confidence → INVOKE immediately
- **0.30-0.60**: Medium confidence → ASK_CLARIFICATION
- **< 0.30**: Low confidence → DO_NOT_INVOKE

### Example Breakdown

For a command-creation agent:
- Explicit "create command" → +0.40 (strong signal)
- Contains "slash command" → +0.30 (strong signal)
- Contains "arguments" + "command" → +0.20 (supporting signal)
- Contains "user invoke" → +0.10 (weak signal)

Threshold: 0.60 for auto-invoke, 0.30 for clarification

## Formatting Standards

### Tables

Use markdown tables with alignment:

```markdown
| Column1 | Column2 | Column3 |
|---------|---------|---------|
| Value   | Value   | Value   |
```

### Code Blocks

Always specify language for syntax highlighting:

```markdown
```bash
command here
```

```python
def function():
    pass
```
```

### Headers

Use ATX-style headers (# ## ###) not underline style:

```markdown
## Section Name
### Subsection Name
```

### Lists

Use consistent indentation (2 spaces for nested lists):

```markdown
- Item 1
  - Sub-item 1
  - Sub-item 2
- Item 2
```

## File Organization

### Command Files

```
{namespace}/commands/{verb}.md
```

Example: `working-tree/commands/create.md` for `/create:working-tree`

### Agent Files

```
{namespace}/agents/{verb-noun}.md
```

Example: `claire/agents/author-agent.md` for `claire-author-agent`

### Skill Files

```
{namespace}/skills/{skill-name}/
  SKILL.md          # Main entry point
  REFERENCE.md      # Technical reference
  FORMS.md          # Structured data collection
  templates/        # Template files
  scripts/          # Helper scripts (if needed)
```

## Versioning and Changelog

Every optimized file should include version information:

```markdown
## VERSION

- Version: X.Y.Z
- Created: YYYY-MM-DD
- Updated: YYYY-MM-DD (reason)
- Purpose: One-line purpose
- Changelog:
  - X.Y.Z (YYYY-MM-DD): Description of changes
  - X.Y.Z (YYYY-MM-DD): Previous changes
```

**Version numbering**:
- **Major (X)**: Complete restructure or AI optimization
- **Minor (Y)**: New features or significant improvements
- **Patch (Z)**: Bug fixes or minor clarifications

## Testing and Validation

### Manual Testing

After optimization, test each component:

1. **Commands**: Invoke with various argument combinations
   ```bash
   /command:name <arg>
   /command:name <arg> --flag value
   /command:name  # missing arg (should error)
   ```

2. **Agents**: Test invocation patterns
   ```
   Test explicit patterns
   Test anti-patterns (should not invoke)
   Test medium-confidence patterns (should ask clarification)
   ```

3. **Skills**: Test progressive disclosure
   ```
   Invoke skill
   Progress through LEVEL 1-4
   Verify templates load correctly
   ```

### Validation Commands

Include validation commands in test cases:

```bash
# File exists
test -f "$FILE" && echo "PASS" || echo "FAIL"

# JSON valid
cat "$FILE" | jq -e '.field == "value"' && echo "PASS" || echo "FAIL"

# Git state
git worktree list | grep -q "$PATH" && echo "PASS" || echo "FAIL"

# File content
grep -q "expected text" "$FILE" && echo "PASS" || echo "FAIL"
```

## Summary

This optimization approach transforms human-readable documentation into deterministic, machine-parseable specifications. The five core patterns (EXECUTION PROTOCOL, ERROR PATTERNS, TOOL PERMISSION MATRIX, TEST CASES, INVOCATION DECISION TREE) provide consistent structure across all components.

Key takeaways:
1. **Explicit over implicit**: Every decision point must be stated
2. **Deterministic algorithms**: Use pseudocode for complex logic
3. **Machine-parseable**: Structure for programmatic interpretation
4. **Safety first**: Explicit permissions and error handling
5. **Testable**: Concrete test cases for every scenario

Use the checklists and patterns in this guide to optimize new components or update existing ones.

---

**Version**: 1.0.0
**Updated**: 2025-11-24
**Next Review**: When adding new component types or patterns

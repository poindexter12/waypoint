# Working Tree Module

**Git worktree management with AI context tracking for isolated development environments.**

The working-tree module provides a complete Claude Code integration for managing Git worktrees with structured metadata. Each worktree becomes an isolated workspace with explicit context that helps AI tools understand the branch purpose, development mode, and constraints.

## Overview

Git worktrees allow you to check out multiple branches simultaneously in separate directories. This module extends that capability by:

- **Automating worktree creation** with standardized naming conventions
- **Tracking development context** via `.ai-context.json` metadata files
- **Providing mode semantics** (main, feature, bugfix, experiment, review) to guide AI behavior
- **Quick reference and templates** for worktree best practices
- **Strategic consulting** for complex worktree organization
- **Simplifying cleanup** with safe destruction commands

## Architecture

This module demonstrates the **correct use** of Claude Code's three component types, following the coordinator framework:

- **Commands** → Simple operations with arguments (create, list, status, destroy, adopt)
- **Agent** → Complex multi-step consulting and strategic guidance
- **Skill** → Cross-cutting knowledge, patterns, and templates

### Why This Matters

Claude Code has three distinct component types, each with specific purposes:

1. **Commands** are for **simple, stateless operations**
   - Execute quickly with arguments
   - No conversational context needed
   - Example: Creating a single worktree

2. **Agents** are for **complex, stateful workflows**
   - Multi-step processes
   - Strategic decision-making
   - Ongoing assistance
   - Example: Migrating entire project to worktrees

3. **Skills** are for **cross-cutting knowledge**
   - Keyword-triggered
   - Progressive disclosure
   - Reusable templates and patterns
   - Example: Best practices and quick reference

This module uses all three correctly.

## Installation

```bash
# From the waypoint root directory
make install working-tree

# Or to a specific directory
make CLAUDE_DIR=/path/to/.claude install working-tree

# Verify installation
make check working-tree
```

## Components

### Commands (Standalone Operations)

All commands operate independently without requiring agent invocation. Use these for day-to-day worktree operations.

#### `/wtm-new` - Create New Worktree

Creates a new worktree with branch, metadata, and documentation.

**Usage**:
```bash
/wtm-new <branch> [--mode <mode>] [--description "<text>"]
```

**Modes**:
- `main` - Minimal changes, stable work
- `feature` - Active development, larger changes allowed (default)
- `bugfix` - Isolated, surgical fixes only
- `experiment` - Prototypes, large swings, unsafe changes allowed
- `review` - Documentation, analysis, audits

**Examples**:
```bash
/wtm-new feature/user-auth
/wtm-new bugfix/session-timeout --mode bugfix --description "Fix session expiry bug"
/wtm-new exp/ai-integration --mode experiment --description "Spike on AI features"
```

**What It Does**:
1. Creates branch if it doesn't exist (off current HEAD)
2. Creates worktree directory with naming convention: `<repo>-<branch-normalized>`
3. Generates `.ai-context.json` with metadata
4. Generates `README.working-tree.md` documentation
5. Returns path to new worktree

**Location**: `~/.claude/commands/working-tree/new.md`

---

#### `/wtm-status` - Show Current Worktree Info

Displays metadata for the current worktree.

**Usage**:
```bash
/wtm-status
```

**Output Example**:
```
Worktree Status
═══════════════════════════════════════════════════════════

Directory:    myapp-feature-login
Branch:       feature/login-refactor
Mode:         feature
Created:      2025-11-23T10:30:00Z

Purpose:
Refactor authentication flow to support OAuth2
```

If no metadata exists, suggests using `/wtm-adopt` to add it.

**Location**: `~/.claude/commands/working-tree/status.md`

---

#### `/wtm-list` - List All Worktrees

Shows all registered worktrees with their metadata in a table format.

**Usage**:
```bash
/wtm-list
```

**Output Example**:
```
Git Worktrees
═══════════════════════════════════════════════════════════

Path                          Branch              Mode         Description
───────────────────────────────────────────────────────────
→ /Users/joe/myapp            main                main         Main development
  /Users/joe/myapp-feat-api   feature/api-v2      feature      New API endpoints
  /Users/joe/myapp-fix-bug    bugfix/login-bug    bugfix       Fix login redirect
```

The current worktree is marked with `→`.

**Location**: `~/.claude/commands/working-tree/list.md`

---

#### `/wtm-destroy` - Remove Worktree

Safely removes a worktree and its metadata.

**Usage**:
```bash
/wtm-destroy <worktree-path>
```

**Important**: This command:
- ✓ Removes the worktree directory
- ✓ Removes metadata files
- ✓ Prunes stale worktree references
- ✓ **Preserves the branch** (by design)
- ✓ Warns about uncommitted changes

**Example**:
```bash
/wtm-destroy ../myapp-feature-login
```

**Location**: `~/.claude/commands/working-tree/destroy.md`

---

#### `/wtm-adopt` - Add Metadata to Existing Worktree

Retroactively adds metadata to a worktree that was created manually or lacks metadata.

**Usage**:
```bash
/wtm-adopt [--mode <mode>] [--description "<text>"]
```

**Example**:
```bash
# From within an existing worktree
/wtm-adopt --mode feature --description "User authentication system"
```

**Location**: `~/.claude/commands/working-tree/adopt.md`

---

### Agent (Strategic Consulting)

The `working-tree-consultant` agent provides expert guidance for complex worktree scenarios.

**Use the agent when you need:**
- Strategic worktree organization planning
- Migration from branch-based to worktree-based workflows
- Multi-step setup guidance (e.g., dev/staging/prod environments)
- Troubleshooting complex worktree issues
- Review of current worktree organization
- Best practices consultation

**Example Invocations**:
- "Help me organize my worktrees for parallel feature development"
- "How do I migrate to a worktree workflow?"
- "Review my current worktree setup and suggest improvements"
- "I have conflicts between my worktrees, help me diagnose"
- "Set up worktrees for dev, staging, and production deployments"

**Do NOT use the agent for:**
- Creating a single worktree → Use `/wtm-new`
- Listing worktrees → Use `/wtm-list`
- Checking status → Use `/wtm-status`
- Simple operations → Use commands

**Location**: `~/.claude/agents/working-tree/consultant.md`

**Key Capabilities**:
- Analyzes current worktree setup
- Recommends organization strategies
- Creates multi-step action plans
- Provides migration guidance
- Troubleshoots complex issues
- Explains best practices with rationale

---

### Skill (Quick Reference & Templates)

The `worktree-guide` skill provides cross-cutting worktree knowledge.

**Auto-triggered by keywords**:
- "worktree best practices"
- "worktree patterns"
- "git worktree help"
- "worktree template"
- "worktree mode semantics"
- "explain worktree metadata"

**What it provides:**
- **Mode semantics reference** - Quick lookup for mode meanings
- **Templates** - Copy-paste templates for metadata files
- **Common patterns** - Examples of typical worktree workflows
- **Progressive disclosure** - Start with overview, dive deeper on request
- **Comprehensive reference** - Full guide in REFERENCE.md

**Location**: `~/.claude/skills/worktree-guide/`

**Supporting Files**:
- `SKILL.md` - Main skill with quick reference
- `REFERENCE.md` - Comprehensive guide (detailed best practices, workflows, troubleshooting)
- `templates/ai-context.json.template` - Metadata file template
- `templates/README.working-tree.template` - README template

**Example Usage**:
```
You: "What mode should I use for a prototype?"

Skill: For prototypes, use **experiment** mode.

Experiment mode allows:
- No restrictions, can be messy
- AI will be aggressive with suggestions
- Expect to discard if prototype fails

Command: /wtm-new exp/prototype-name --mode experiment
```

---

## When to Use What

### Quick Decision Guide

| Your Need | Use This |
|-----------|----------|
| Create a worktree | `/wtm-new <branch>` command |
| See all worktrees | `/wtm-list` command |
| Check current worktree | `/wtm-status` command |
| Remove a worktree | `/wtm-destroy <path>` command |
| Add metadata | `/wtm-adopt` command |
| Understand mode semantics | Mention "worktree mode semantics" (triggers skill) |
| Get best practices | Mention "worktree best practices" (triggers skill) |
| Strategic guidance | Invoke `working-tree-consultant` agent |
| Migration help | Invoke `working-tree-consultant` agent |
| Complex troubleshooting | Invoke `working-tree-consultant` agent |

### Decision Tree

```
Do you need to DO something?
  ├─ Yes: Simple operation (create, list, status, destroy, adopt)
  │   └─ Use COMMAND (/wtm-*)
  │
  ├─ No: Want to LEARN something?
  │   ├─ Quick reference/templates
  │   │   └─ Mention keywords → SKILL activates
  │   │
  │   └─ Strategic consulting/complex scenarios
  │       └─ Invoke working-tree-consultant AGENT
```

---

## Metadata Structure

### `.ai-context.json`

Every managed worktree contains a `.ai-context.json` file at its root:

```json
{
  "worktree": "myapp-feature-login",
  "branch": "feature/login-refactor",
  "mode": "feature",
  "created": "2025-11-23T10:30:00Z",
  "description": "Refactor authentication flow to support OAuth2"
}
```

**Fields**:
- `worktree`: Directory name (not full path)
- `branch`: Git branch name
- `mode`: Development mode (main|feature|bugfix|experiment|review)
- `created`: UTC timestamp in ISO 8601 format
- `description`: Freeform description of purpose

**Template available**: See `skills/worktree-guide/templates/ai-context.json.template`

### `README.working-tree.md`

Human-readable documentation generated alongside `.ai-context.json`:

```markdown
# Worktree: myapp-feature-login

**Branch:** `feature/login-refactor`
**Mode:** `feature`
**Created:** 2025-11-23T10:30:00Z

## Purpose

Refactor authentication flow to support OAuth2

## Mode Semantics

- **main**: Minimal changes, stable work only
- **feature**: Active development, larger changes allowed
- **bugfix**: Isolated, surgical fixes only
- **experiment**: Prototypes, large swings, unsafe changes allowed
- **review**: Documentation, analysis, audits

...
```

**Template available**: See `skills/worktree-guide/templates/README.working-tree.template`

---

## Mode Semantics

Modes guide AI behavior and set expectations for the scope of changes:

| Mode | Purpose | Change Scope | AI Behavior |
|------|---------|-------------|-------------|
| `main` | Production stability | Minimal, conservative | Conservative, safety-focused |
| `feature` | New functionality | Larger changes, active development | Helpful, proactive |
| `bugfix` | Isolated bug fixes | Surgical, focused fixes only | Focused, warns about scope creep |
| `experiment` | Prototyping | Large, unsafe changes allowed | Aggressive suggestions, OK with rough code |
| `review` | Code review, docs | Analysis, documentation | Analytical, critical feedback |

**Example Usage**:
- Creating a new API endpoint → `feature`
- Fixing a null pointer crash → `bugfix`
- Testing a new architecture → `experiment`
- Writing documentation → `review`
- Hotfix for production → `main`

**For detailed mode guide**: Mention "worktree mode semantics" to trigger the skill

---

## Naming Convention

Worktrees follow a predictable naming pattern:

```
<repo-name>-<branch-name-normalized>
```

**Normalization**:
- Replace `/` with `-`
- Replace `_` with `-`
- Lowercase

**Examples**:
- Branch: `feature/user-auth` → Directory: `myapp-feature-user-auth`
- Branch: `bugfix/session-expiry` → Directory: `myapp-bugfix-session-expiry`
- Branch: `exp/ai-spike` → Directory: `myapp-exp-ai-spike`

This makes worktrees:
- Easy to identify
- Safe for filesystem operations
- Consistent across projects

---

## Workflows

### Creating a Feature Branch Worktree

```bash
# Create new feature worktree
/wtm-new feature/payment-processing --description "Add Stripe integration"

# Output:
# Created worktree successfully!
#   Path: ../myapp-feature-payment-processing
#   Branch: feature/payment-processing
#   Mode: feature (inferred from branch name)

# Navigate and start working
cd ../myapp-feature-payment-processing
# Work on feature...
```

### Quick Bug Fix

```bash
# Create bugfix worktree
/wtm-new bugfix/null-check --mode bugfix --description "Fix null pointer in auth"

# AI knows to keep changes minimal and focused
cd ../myapp-bugfix-null-check
# Make surgical fix...

# Clean up when done
cd ../myapp
/wtm-destroy ../myapp-bugfix-null-check
```

### Experimental Work

```bash
# Create experiment worktree
/wtm-new exp/graphql-migration --mode experiment --description "Test GraphQL migration"

# AI knows larger, riskier changes are acceptable
cd ../myapp-exp-graphql-migration
# Try new approaches...

# Either:
# - Success → Create proper feature worktree for real implementation
# - Failure → Destroy and document learnings
```

### Parallel Feature Development

```bash
# Morning: Create API worktree
/wtm-new feature/api-v2 --description "New REST API endpoints"
cd ../myapp-feature-api-v2
# Work on API...

# Afternoon: Create UI worktree
/wtm-new feature/ui-redesign --description "Frontend redesign"
cd ../myapp-feature-ui-redesign
# Work on UI...

# No git stash needed! Context switching is instant: just `cd`

# Check all active work
/wtm-list
```

### Migration to Worktrees

**For complex migration scenarios**, invoke the consultant agent:

```
"Help me migrate my project to a worktree workflow. I currently have 8 branches and switch between them frequently."
```

The consultant will:
1. Analyze your current branches
2. Recommend worktree organization
3. Create a step-by-step migration plan
4. Guide you through implementation
5. Provide validation checkpoints

---

## Safety & Constraints

The working-tree module enforces these rules:

- ✓ **Isolation**: Each worktree is treated as independent
- ✓ **Validation**: Commands check if branch is already checked out
- ✓ **No auto-delete**: Never removes worktrees without explicit command
- ✓ **Branch preservation**: `/wtm-destroy` never deletes branches
- ✓ **Uncommitted change warnings**: Warns before destroying worktrees with uncommitted work
- ✓ **Mode validation**: Ensures mode is one of the five valid values
- ✓ **Metadata integrity**: Validates JSON structure before writing

---

## Troubleshooting

### "Branch already has a worktree"

**Cause**: Trying to create a second worktree for the same branch.

**Solution**:
```bash
# See what's checked out where
/wtm-list

# Option 1: Use existing worktree
cd ../existing-worktree

# Option 2: Destroy old worktree first
/wtm-destroy ../old-worktree
/wtm-new feature/branch-name
```

### Missing Metadata

**Cause**: Worktree was created manually without `/wtm-new`.

**Solution**:
```bash
cd /path/to/worktree
/wtm-adopt --mode feature --description "Purpose of this worktree"
```

### Stale Worktrees

**Cause**: Manually deleted a worktree directory, but Git still tracks it.

**Solution**:
```bash
git worktree prune
/wtm-list  # Verify cleanup
```

### Too Many Worktrees

**Cause**: Created many worktrees and lost track.

**Solution**:
```bash
# Audit all worktrees
/wtm-list

# Destroy completed work
/wtm-destroy ../myapp-feature-completed

# For strategic cleanup guidance, invoke consultant:
# "Help me organize my worktrees, I have too many"
```

### Understanding Best Practices

**For quick reference**, mention trigger keywords:
- "worktree best practices"
- "worktree patterns"

**For strategic consulting**, invoke the agent:
- "Review my worktree organization"
- "What's the best worktree strategy for my workflow?"

---

## Advanced Usage

### Custom Installation Directory

```bash
# Install to project-specific directory
make CLAUDE_DIR=$(pwd)/.claude install working-tree
```

### Copy Instead of Symlink

```bash
# Copy files instead of symlinking
make MODE=copy install working-tree
```

### Uninstall

```bash
# Remove working-tree module
make uninstall working-tree
```

---

## Files Installed

After installation, these files are in `~/.claude/` (or your specified directory):

```
~/.claude/
├── commands/working-tree/
│   ├── new.md           # /wtm-new command
│   ├── status.md        # /wtm-status command
│   ├── list.md          # /wtm-list command
│   ├── destroy.md       # /wtm-destroy command
│   └── adopt.md         # /wtm-adopt command
│
├── agents/working-tree/
│   └── consultant.md    # working-tree-consultant agent
│
└── skills/worktree-guide/
    ├── SKILL.md         # Main skill (quick reference)
    ├── REFERENCE.md     # Comprehensive guide
    └── templates/
        ├── ai-context.json.template
        └── README.working-tree.template
```

---

## Contributing

To improve the working-tree module:

1. **Commands**: Edit `commands/*.md`
2. **Agent**: Edit `agents/consultant.md`
3. **Skill**: Edit `skills/worktree-guide/SKILL.md` or `REFERENCE.md`
4. **Templates**: Edit files in `skills/worktree-guide/templates/`
5. Test changes locally
6. Submit PR with description of improvements

### Architecture Principles

This module follows the coordinator framework from `claire/agents/coordinator.md`:

- **Commands** are stateless, simple operations
- **Agent** provides strategic, stateful consulting
- **Skill** offers cross-cutting knowledge and templates

If adding features, ensure they're in the right component type:
- Simple operation with args → Command
- Complex multi-step workflow → Agent
- Cross-cutting knowledge → Skill

---

## Related Documentation

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Main Waypoint README](../README.md)
- [Claude Code Documentation](https://code.claude.com)
- [Claire Coordinator Framework](../claire/agents/coordinator.md)

---

## License

MIT License - See [LICENSE](../LICENSE) for details.

# Working Tree Module

**Git worktree management with AI context tracking for isolated development environments.**

The working-tree module provides Claude agents and commands for managing Git worktrees with structured metadata. Each worktree becomes an isolated workspace with explicit context that helps AI tools understand the branch purpose, development mode, and constraints.

## Overview

Git worktrees allow you to check out multiple branches simultaneously in separate directories. This module extends that capability by:

- **Automating worktree creation** with standardized naming conventions
- **Tracking development context** via `.ai-context.json` metadata files
- **Enforcing isolation** so AI tools understand workspace boundaries
- **Providing mode semantics** (main, feature, bugfix, experiment, review) to guide AI behavior
- **Simplifying cleanup** with safe destruction commands

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

### Agent: `@working-tree:manager`

The core agent that orchestrates all worktree operations. It handles creation, destruction, status checks, and metadata management while enforcing safety rules.

**Location**: `~/.claude/agents/working-tree/manager.md`

**Key Behaviors**:
- Treats each worktree as isolated
- Reads `.ai-context.json` before acting
- Never writes outside target worktree
- Never auto-deletes (except when explicitly running destroy)
- Never modifies branches without explicit instruction
- Validates branch isn't already checked out before creating worktree

### Commands

All commands are prefixed with `/wtm-` (worktree manager) and are available after installation.

#### `/wtm-new` - Create New Worktree

Creates a new worktree with branch, metadata, and documentation.

**Usage**:
```
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
2. Creates worktree directory with naming convention: `<repo>-<branch-with-slashes-replaced>`
3. Generates `.ai-context.json` with metadata
4. Generates `README.working-tree.md` documentation
5. Returns path to new worktree

#### `/wtm-status` - Show Current Worktree Info

Displays metadata for the current worktree.

**Usage**:
```
/wtm-status
```

**Output**:
```
Worktree: myapp-feature-login
Branch: feature/login
Mode: feature
Description: refactor login flow
Created: 2025-01-01T00:00:00Z
```

If no metadata exists, suggests using `/wtm-adopt` to add it.

#### `/wtm-list` - List All Worktrees

Shows all registered worktrees with their metadata.

**Usage**:
```
/wtm-list
```

**Output**:
```
Worktrees for myapp:

1. /path/to/myapp (main)
   Branch: main
   [No metadata - use /wtm-adopt]

2. /path/to/myapp-feature-login
   Branch: feature/login
   Mode: feature
   Description: refactor login flow
```

#### `/wtm-destroy` - Remove Worktree

Safely removes a worktree and its metadata.

**Usage**:
```
/wtm-destroy <worktree-path>
```

**Important**: This command:
-  Removes the worktree directory
-  Removes metadata files
-  Prunes stale worktree references
- L **Does NOT delete the branch** (by design)

**Example**:
```bash
/wtm-destroy ../myapp-feature-login
```

#### `/wtm-adopt` - Add Metadata to Existing Worktree

Retroactively adds metadata to a worktree that was created manually.

**Usage**:
```
/wtm-adopt [--mode <mode>] [--description "<text>"]
```

**Example**:
```bash
# From within an existing worktree
/wtm-adopt --mode feature --description "User authentication system"
```

## Metadata Structure

### `.ai-context.json`

Every managed worktree contains a `.ai-context.json` file at its root:

```json
{
  "worktree": "myapp-feature-login",
  "branch": "feature/login",
  "mode": "feature",
  "created": "2025-01-01T00:00:00Z",
  "description": "refactor login flow"
}
```

**Fields**:
- `worktree`: Directory name
- `branch`: Git branch name
- `mode`: Development mode (main|feature|bugfix|experiment|review)
- `created`: UTC timestamp of creation
- `description`: Freeform description of purpose

### `README.working-tree.md`

Human-readable documentation generated alongside `.ai-context.json`:

```markdown
Worktree: myapp-feature-login
Branch: feature/login
Mode: feature
Purpose: refactor login flow
Created: 2025-01-01T00:00:00Z

This directory is an independent Git worktree attached to the main repository.
```

## Mode Semantics

Modes guide AI behavior and set expectations for the scope of changes:

| Mode | Purpose | Change Scope |
|------|---------|-------------|
| `main` | Stable, production-ready work | Minimal, conservative changes |
| `feature` | New functionality development | Larger changes, active development |
| `bugfix` | Isolated bug fixes | Surgical, focused fixes only |
| `experiment` | Prototyping and exploration | Large, unsafe changes allowed |
| `review` | Code review, documentation | Analysis, audits, documentation |

**Example Usage**:
- Creating a new API endpoint ’ `feature`
- Fixing a null pointer crash ’ `bugfix`
- Testing a new architecture ’ `experiment`
- Writing documentation ’ `review`
- Hotfix for production ’ `main`

## Naming Convention

Worktrees follow a predictable naming pattern:

```
<repo-name>-<branch-name-with-slashes-replaced>
```

**Examples**:
- Branch: `feature/user-auth` ’ Directory: `myapp-feature-user-auth`
- Branch: `bugfix/session-expiry` ’ Directory: `myapp-bugfix-session-expiry`
- Branch: `exp/ai-spike` ’ Directory: `myapp-exp-ai-spike`

This makes worktrees:
- Easy to identify
- Safe for filesystem operations
- Consistent across projects

## Workflows

### Creating a Feature Branch Worktree

```bash
# Create new feature worktree
/wtm-new feature/payment-processing --mode feature --description "Add Stripe integration"

# Claude creates:
# - Branch: feature/payment-processing
# - Directory: myapp-feature-payment-processing/
# - Metadata: .ai-context.json + README.working-tree.md

# Navigate and start working
cd ../myapp-feature-payment-processing
# Work on feature...
```

### Quick Bug Fix

```bash
# Create bugfix worktree
/wtm-new bugfix/null-check --mode bugfix --description "Fix null pointer in auth"

# Claude knows to keep changes minimal and focused
cd ../myapp-bugfix-null-check
# Make surgical fix...

# Clean up when done
/wtm-destroy ../myapp-bugfix-null-check
```

### Experimental Work

```bash
# Create experiment worktree
/wtm-new exp/graphql-migration --mode experiment --description "Test GraphQL migration"

# Claude knows larger, riskier changes are acceptable
cd ../myapp-exp-graphql-migration
# Try new approaches...
```

### Adopting Existing Worktrees

```bash
# You created a worktree manually
git worktree add ../myapp-refactor main

# Navigate to it
cd ../myapp-refactor

# Add metadata
/wtm-adopt --mode review --description "Code review and cleanup"
```

## Git Commands Reference

The agent uses these Git commands internally:

```bash
# Detect current worktree
git rev-parse --show-toplevel
git rev-parse --abbrev-ref HEAD

# List all worktrees
git worktree list --porcelain

# Create worktree
git worktree add <directory> <branch>

# Remove worktree
git worktree remove --force <directory>

# Prune stale references
git worktree prune
```

## Safety & Constraints

The working-tree agent enforces these rules:

-  **Isolation**: Each worktree is treated as independent
-  **Validation**: Checks if branch is already checked out
-  **No auto-delete**: Never removes worktrees without explicit command
-  **Branch preservation**: `/wtm-destroy` never deletes branches
-  **Metadata first**: Always reads `.ai-context.json` before acting
-  **Bounded operations**: Never writes outside target worktree

## Troubleshooting

### "Branch already checked out"

Git worktrees can't check out the same branch twice. Use `/wtm-list` to see what's checked out where.

**Solution**: Either destroy the existing worktree or create a different branch.

### Missing Metadata

If you manually created a worktree, it won't have metadata.

**Solution**: Navigate to the worktree and run `/wtm-adopt`.

### Stale Worktrees

If you manually deleted a worktree directory, Git may still track it.

**Solution**:
```bash
git worktree prune
```

### Checking Worktree Status

To see all worktrees from Git's perspective:
```bash
git worktree list
```

To see metadata:
```bash
/wtm-list
```

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

## Contributing

To improve the working-tree module:

1. Edit agent spec: `agents/manager.md`
2. Edit command specs: `commands/*.md`
3. Test changes locally
4. Submit PR with description of improvements

## Related Documentation

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Main Waypoint README](../README.md)
- [Claude Code Documentation](https://code.claude.com)

## License

MIT License - See [LICENSE](../LICENSE) for details.

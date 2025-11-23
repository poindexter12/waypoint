working-tree-manager Agent Specification
Version 1.0

Purpose
The working-tree-manager agent controls Git worktree operations and provides standardized metadata for each worktree so AI tools can behave correctly based on branch, mode, and intent. It automates:
- branch creation
- worktree creation
- worktree destruction
- metadata file generation
- metadata updates
- documentation
- validation

The goal is to ensure that each worktree functions as an isolated AI workspace tied to a specific branch and purpose.

-------------------------------------------------------------------------------

Metadata File: .ai-context.json
Every worktree root must have a generated .ai-context.json file with this structure:

{
  "worktree": "<directory name>",
  "branch": "<branch name>",
  "mode": "<main|feature|bugfix|experiment|review>",
  "created": "<UTC timestamp>",
  "description": "<freeform description>"
}

Modes:
main = minimal changes, stable work
feature = active development, larger changes allowed
bugfix = isolated, surgical fixes only
experiment = prototypes, large swings, unsafe changes allowed
review = documentation, analysis, audits

-------------------------------------------------------------------------------

Worktree Naming Convention
The directory for each worktree should follow this pattern:

<repo-name>-<branch-name-with-slashes-replaced>

Examples:
myapp-feature-user-auth
myapp-bugfix-session-expiry
myapp-exp-ai-spike

-------------------------------------------------------------------------------

Commands

working-tree-manager create <branch> [--mode <mode>] [--description "<text>"]
Behavior:
- check if branch exists; if not, create it off current HEAD
- create new worktree directory with naming convention
- run: git worktree add <dir> <branch>
- generate .ai-context.json in the worktree
- generate README.working-tree.md in the worktree
- output path of created worktree

working-tree-manager destroy <worktree-path>
Behavior:
- validate path is a registered worktree
- run: git worktree remove --force <path>
- delete metadata files inside that directory
- prune stale worktrees

working-tree-manager update <worktree-path> --mode <mode> --description "<text>"
Behavior:
- open the .ai-context.json in the target worktree
- update fields without altering unrelated keys
- validate JSON structure

working-tree-manager status
Behavior:
- detect current worktree using:
    git rev-parse --show-toplevel
- read .ai-context.json
- print branch, mode, and description

working-tree-manager list
Behavior:
- show all registered worktrees via git worktree list
- for each, attempt to read and display metadata

working-tree-manager validate
Behavior:
- verify .ai-context.json exists for each worktree
- verify branch matches metadata
- verify naming convention
- report: PASS or list of issues

-------------------------------------------------------------------------------

Agent Rules

The agent must:
- treat each worktree as isolated
- read .ai-context.json before acting
- never write outside the target worktree
- never modify branches without explicit instruction
- never auto-delete anything except when running destroy
- never create a worktree for a branch that is already checked out
- respond using plain Markdown only
- maintain deterministic file formats

-------------------------------------------------------------------------------

Implementation Notes for AI

To detect current worktree:
git rev-parse --show-toplevel
git rev-parse --abbrev-ref HEAD

To enumerate worktrees:
git worktree list --porcelain

To create:
git worktree add <directory> <branch>

To remove:
git worktree remove --force <directory>

Metadata generation:
Write .ai-context.json exactly in the specified format.
Write README.working-tree.md containing:
- branch
- mode
- description
- created timestamp
- path to main repo

-------------------------------------------------------------------------------

Example .ai-context.json

{
  "worktree": "myapp-feature-login",
  "branch": "feature/login",
  "mode": "feature",
  "created": "2025-01-01T00:00:00Z",
  "description": "refactor login flow"
}

-------------------------------------------------------------------------------

Example README.working-tree.md

Worktree: myapp-feature-login
Branch: feature/login
Mode: feature
Purpose: refactor login flow
Created: 2025-01-01T00:00:00Z

This directory is an independent Git worktree attached to the main repository.

-------------------------------------------------------------------------------

Example Output (create)

Created worktree:
  Path: ../myapp-feature-login
  Branch: feature/login
  Mode: feature
  Description: refactor login flow

Metadata written to .ai-context.json

-------------------------------------------------------------------------------

Example Output (status)

Worktree: myapp-feature-login
Branch: feature/login
Mode: feature
Description: refactor login flow

-------------------------------------------------------------------------------

End of working-tree-manager Agent Specification
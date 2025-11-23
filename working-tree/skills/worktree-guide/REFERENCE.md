## Git Worktree Guide - Comprehensive Reference

Complete guide to git worktrees with AI metadata integration for optimal development workflows.

## Table of Contents

1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [Mode Semantics Deep Dive](#mode-semantics-deep-dive)
4. [Naming Conventions](#naming-conventions)
5. [Workflow Patterns](#workflow-patterns)
6. [Metadata Files](#metadata-files)
7. [Organization Strategies](#organization-strategies)
8. [Team Collaboration](#team-collaboration)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Topics](#advanced-topics)

---

## Overview

### What Are Git Worktrees?

Git worktrees allow you to check out multiple branches simultaneously in separate directories, all connected to the same repository. This eliminates the need to `git stash` or switch branches when context-switching.

**Traditional Workflow:**
```bash
# Working on feature
git checkout feature/user-auth
# ... work ...

# Need to fix bug
git stash
git checkout main
# ... fix bug ...

# Back to feature
git checkout feature/user-auth
git stash pop
```

**Worktree Workflow:**
```bash
# Create worktrees once
/wtm-new feature/user-auth
/wtm-new main --mode main

# Switch by changing directories
cd ../myapp-feature-user-auth  # Feature work
cd ../myapp  # Bug fix

# No stashing needed!
```

### AI Metadata Integration

Each worktree has `.ai-context.json` that tells AI tools:
- What kind of work is being done (mode)
- Purpose of the worktree (description)
- When it was created
- Which branch it tracks

This allows AI to:
- Adjust suggestion style (conservative for `main`, aggressive for `experiment`)
- Understand context automatically
- Provide relevant warnings
- Suggest appropriate tools

---

## Core Concepts

### Worktree Structure

```
Parent directory/
├── myapp/                          # Main repository (or a worktree)
│   ├── .git/                       # Git metadata (worktrees link here)
│   ├── .ai-context.json            # AI metadata
│   └── README.working-tree.md      # Human-readable info
│
├── myapp-feature-user-auth/        # Feature worktree
│   ├── .git → ../myapp/.git/       # Links to main .git
│   ├── .ai-context.json
│   └── README.working-tree.md
│
└── myapp-bugfix-timeout/           # Bugfix worktree
    ├── .git → ../myapp/.git/
    ├── .ai-context.json
    └── README.working-tree.md
```

### Metadata Files

**.ai-context.json** (Machine-Readable)
- JSON format
- Read by AI tools automatically
- Contains: worktree, branch, mode, created, description

**README.working-tree.md** (Human-Readable)
- Markdown format
- Documentation for developers
- Contains: mode semantics, paths, purpose

---

## Mode Semantics Deep Dive

### main - Production Stability

**Philosophy:** This is production-ready code. Changes must be minimal, tested, and safe.

**Use Cases:**
- Production hotfixes
- Critical security patches
- Emergency bug fixes
- Stable baseline for comparisons

**Restrictions:**
- No experimental changes
- No refactoring unless necessary for fix
- Minimal scope
- Full test coverage required

**AI Behavior:**
- Conservative suggestions
- Focuses on safety
- Warns about risks
- Suggests defensive code
- Recommends extensive testing

**Example:**
```bash
/wtm-new main --mode main --description "Production baseline for hotfixes"
```

**Workflow:**
```bash
cd ../myapp-main
# Critical bug found in production
git pull origin main
# Make minimal surgical fix
git commit -m "fix: critical security vulnerability in auth"
git push origin main
# Deploy immediately
```

### feature - Active Development

**Philosophy:** This is where real work happens. Experiment, iterate, and improve.

**Use Cases:**
- New features
- Enhancements to existing features
- Refactoring
- Performance improvements
- Most day-to-day work

**Restrictions:**
- None! Be creative
- Can make breaking changes
- Can refactor extensively
- Can add dependencies

**AI Behavior:**
- Helpful and proactive
- Suggests improvements freely
- Offers refactoring ideas
- Recommends best practices
- Encourages good patterns

**Example:**
```bash
/wtm-new feature/user-dashboard --mode feature --description "New user settings dashboard with profile management"
```

**Workflow:**
```bash
cd ../myapp-feature-user-dashboard
# Develop freely
npm install new-library
# Refactor as needed
# Add tests
# Iterate until ready
git push origin feature/user-dashboard
# Create PR when ready
```

### bugfix - Surgical Precision

**Philosophy:** Fix one specific bug without touching anything else.

**Use Cases:**
- Specific bug fixes
- Regression fixes
- Issue resolution
- Targeted corrections

**Restrictions:**
- Minimal scope (only fix the bug)
- No "while I'm here" changes
- No refactoring (unless required for fix)
- No new features

**AI Behavior:**
- Focused on the specific issue
- Warns about scope creep
- Suggests minimal changes
- Recommends adding tests for the bug
- Keeps changes isolated

**Example:**
```bash
/wtm-new bugfix/session-timeout --mode bugfix --description "Fix session timeout not respecting user settings (issue #427)"
```

**Workflow:**
```bash
cd ../myapp-bugfix-session-timeout
# Reproduce the bug
# Write test that fails
# Fix minimal code to make test pass
# Verify no other changes
git diff  # Should show minimal changes
git push origin bugfix/session-timeout
```

### experiment - Prototype Freely

**Philosophy:** This might get thrown away. Optimize for learning, not production quality.

**Use Cases:**
- Proof of concepts
- Technology spikes
- Architecture exploration
- A/B testing approaches
- Learning new libraries

**Restrictions:**
- None - can be messy
- Don't worry about code quality
- Tests optional
- Can break conventions

**AI Behavior:**
- Aggressive with suggestions
- OK with rough code
- Suggests quick solutions
- Encourages trying things
- Less concerned with best practices

**Example:**
```bash
/wtm-new exp/graphql-migration --mode experiment --description "Spike: evaluate GraphQL migration feasibility"
```

**Workflow:**
```bash
cd ../myapp-exp-graphql-migration
# Try things quickly
# Don't worry about polish
# Document learnings
# If successful → create feature worktree for proper implementation
# If failed → /wtm-destroy and document why
```

### review - Analytical Mindset

**Philosophy:** Read and analyze code without modifying production code.

**Use Cases:**
- Code review (PRs)
- Security audits
- Documentation work
- Performance analysis
- Understanding unfamiliar code

**Restrictions:**
- Read-only mindset (changes OK for docs/tests)
- No production code modification
- Analysis and documentation only

**AI Behavior:**
- Analytical and critical
- Points out issues
- Suggests improvements (for author to implement)
- Focuses on understanding
- Explains complex code

**Example:**
```bash
/wtm-new review/pr-543 --mode review --description "Review authentication refactor PR #543"
```

**Workflow:**
```bash
cd ../myapp-review-pr-543
git fetch origin pull/543/head:review/pr-543
git checkout review/pr-543
# Read and analyze
# Add review comments
# Test changes
# Approve or request changes in PR
# When done → /wtm-destroy
```

---

## Naming Conventions

### Structure Pattern

**Format:** `<repo-name>-<type>-<description>`

**Examples:**
- `myapp-feature-user-auth`
- `myapp-bugfix-session-timeout`
- `myapp-exp-graphql-spike`
- `api-server-feature-rate-limiting`

### Prefix Indicators

Use branch prefixes to auto-infer modes:
- `feature/` → mode: feature
- `bugfix/` or `fix/` → mode: bugfix
- `exp/` or `experiment/` → mode: experiment
- `review/` → mode: review
- `main` or `master` → mode: main

### Best Practices

**DO:**
- Use lowercase with hyphens: `user-auth` ✅
- Be descriptive: `feature/oauth2-integration` ✅
- Include issue numbers: `bugfix/issue-427-timeout` ✅
- Use consistent prefixes: `feature/`, `bugfix/`, `exp/` ✅

**DON'T:**
- Use generic names: `test`, `temp`, `new` ❌
- Use spaces or special chars: `user auth`, `user_auth` ❌
- Be vague: `fix-bug`, `feature-1` ❌
- Mix naming styles ❌

---

## Workflow Patterns

### Pattern 1: Feature Development

**Scenario:** Developing a new feature over several days/weeks

**Setup:**
```bash
/wtm-new feature/user-dashboard --mode feature --description "User settings dashboard with profile editing"
```

**Workflow:**
```bash
# Day 1: Setup
cd ../myapp-feature-user-dashboard
npm install needed-packages
git commit -m "feat: initial dashboard setup"

# Day 2-5: Development
# Work iteratively, commit frequently
git commit -m "feat: add profile form"
git commit -m "feat: add settings panel"

# Day 6: Review
git push origin feature/user-dashboard
# Create PR

# After merge
cd ../myapp
/wtm-destroy ../myapp-feature-user-dashboard
```

### Pattern 2: Parallel Feature Work

**Scenario:** Working on multiple features simultaneously

**Setup:**
```bash
/wtm-new feature/api-v2 --description "New API endpoints"
/wtm-new feature/ui-redesign --description "Frontend redesign"
/wtm-new feature/user-auth --description "OAuth2 authentication"
```

**Workflow:**
```bash
# Morning: API work
cd ../myapp-feature-api-v2
# ... work on API ...

# Afternoon: UI work
cd ../myapp-feature-ui-redesign
# ... work on UI ...

# Context switching is instant - no git stash!
```

**Management:**
```bash
# Check status of all work
/wtm-list

# See current worktree
/wtm-status
```

### Pattern 3: Urgent Hotfix During Feature Work

**Scenario:** Critical bug found while working on feature

**Setup:**
```bash
# Already working in feature worktree
cd ../myapp-feature-user-dashboard

# Urgent bug reported!
# Don't stash - just create bugfix worktree
cd ../myapp
/wtm-new bugfix/critical-auth-flaw --mode bugfix

# Fix the bug
cd ../myapp-bugfix-critical-auth-flaw
# ... fix ...
git push origin bugfix/critical-auth-flaw

# Back to feature work
cd ../myapp-feature-user-dashboard
# Continue where you left off - no stash pop needed!
```

### Pattern 4: Deployment Environment Management

**Scenario:** Managing dev, staging, and production deployments

**Setup:**
```bash
/wtm-new develop --mode feature --description "Development environment"
/wtm-new staging --mode review --description "Staging for QA testing"
/wtm-new production --mode main --description "Production deployment code"
```

**Workflow:**
```bash
# Deploy to dev
cd ../myapp-develop
git pull origin develop
npm install
npm run build
npm run deploy:dev

# When ready for staging
cd ../myapp-staging
git pull origin staging
npm install
npm run build
npm run deploy:staging

# After QA approval
cd ../myapp-production
git pull origin main
npm install
npm run build
npm run deploy:prod
```

Each environment has its own:
- Dependencies (node_modules)
- Build artifacts
- Configuration files (.env.dev, .env.staging, .env.prod)

### Pattern 5: Code Review Workflow

**Scenario:** Reviewing PRs without disrupting current work

**Setup:**
```bash
# For each PR to review
/wtm-new review/pr-<number> --mode review --description "Review PR #<number>: <title>"
```

**Workflow:**
```bash
# Create review worktree
cd ../myapp
/wtm-new review/pr-543 --mode review

cd ../myapp-review-pr-543
# Fetch the PR branch
git fetch origin pull/543/head:review/pr-543
git checkout review/pr-543

# Review the code
# Run tests
npm test

# Check the changes
git diff main...review/pr-543

# Add review comments in GitHub
# When done
cd ../myapp
/wtm-destroy ../myapp-review-pr-543
```

---

## Metadata Files

### .ai-context.json Structure

**Format:**
```json
{
  "worktree": "string - directory name",
  "branch": "string - git branch name",
  "mode": "main|feature|bugfix|experiment|review",
  "created": "string - ISO 8601 UTC timestamp",
  "description": "string - freeform purpose description"
}
```

**Example:**
```json
{
  "worktree": "myapp-feature-user-auth",
  "branch": "feature/user-authentication",
  "mode": "feature",
  "created": "2025-11-23T10:30:00Z",
  "description": "Implement OAuth2 and JWT authentication with refresh tokens"
}
```

**Field Details:**

- **worktree**: Just the directory name (not full path)
  - Example: `myapp-feature-user-auth`
  - Used by AI to identify context

- **branch**: Full git branch name
  - Example: `feature/user-authentication`
  - Must match actual git branch

- **mode**: One of five modes
  - Values: `main`, `feature`, `bugfix`, `experiment`, `review`
  - Affects AI behavior significantly

- **created**: ISO 8601 timestamp in UTC
  - Format: `YYYY-MM-DDTHH:MM:SSZ`
  - Example: `2025-11-23T10:30:00Z`
  - Timezone must be UTC (trailing Z)

- **description**: Freeform text
  - Can be empty string
  - Keep concise (one sentence ideal)
  - Explain purpose, not implementation

### README.working-tree.md Structure

**Purpose:** Human-readable documentation about the worktree

**Auto-Generated Content:**
- Worktree name and branch
- Mode and its semantics
- Creation timestamp
- Purpose/description
- Path information
- Mode reference guide

**Example:**
```markdown
# Worktree: myapp-feature-user-auth

**Branch:** `feature/user-authentication`
**Mode:** `feature`
**Created:** 2025-11-23T10:30:00Z

## Purpose

Implement OAuth2 and JWT authentication with refresh tokens

## Mode Semantics

- **main**: Minimal changes, stable work only
- **feature**: Active development, larger changes allowed
- **bugfix**: Isolated, surgical fixes only
- **experiment**: Prototypes, large swings, unsafe changes allowed
- **review**: Documentation, analysis, audits

## About This Worktree

This directory is an independent Git worktree attached to the main repository.

- Main repo: /Users/joe/Code/myapp
- Worktree path: /Users/joe/Code/myapp-feature-user-auth
- Branch: feature/user-authentication

See `.ai-context.json` for machine-readable metadata.
```

---

## Organization Strategies

### Strategy 1: Feature-Centric (Recommended)

**Philosophy:** One worktree per active feature/task

**Structure:**
```
myapp/                     # main repo (mode: main or feature)
myapp-feature-api-v2/     # mode: feature
myapp-feature-ui-refresh/ # mode: feature
myapp-bugfix-auth-leak/   # mode: bugfix
```

**Best For:**
- Small to medium teams
- Feature-driven development
- Agile workflows
- Parallel feature development

**Commands:**
```bash
/wtm-adopt --mode main --description "Main repository"
/wtm-new feature/api-v2
/wtm-new feature/ui-refresh
/wtm-new bugfix/auth-leak --mode bugfix
```

### Strategy 2: Environment-Based

**Philosophy:** Permanent worktrees for each environment

**Structure:**
```
myapp-develop/       # mode: feature (develop branch)
myapp-staging/       # mode: review (staging branch)
myapp-production/    # mode: main (main branch)
myapp-feature-X/     # mode: feature (temporary feature work)
```

**Best For:**
- DevOps-heavy workflows
- Multiple deployment environments
- Configuration management
- Testing different versions

**Commands:**
```bash
/wtm-new develop --mode feature --description "Development environment"
/wtm-new staging --mode review --description "Staging for QA"
/wtm-new main --mode main --description "Production code"
```

### Strategy 3: Experimentation-Heavy

**Philosophy:** Many experiments, few stable features

**Structure:**
```
myapp/                    # mode: main (stable baseline)
myapp-exp-approach-a/    # mode: experiment
myapp-exp-approach-b/    # mode: experiment
myapp-exp-new-framework/ # mode: experiment
```

**Best For:**
- Research projects
- Prototyping
- Technology evaluation
- Rapid experimentation

**Commands:**
```bash
/wtm-adopt --mode main --description "Stable baseline for comparisons"
/wtm-new exp/approach-a --mode experiment
/wtm-new exp/approach-b --mode experiment
```

### Strategy 4: Review-Focused

**Philosophy:** Code quality and review are primary

**Structure:**
```
myapp/                  # mode: feature (main development)
myapp-review-pr-123/   # mode: review
myapp-review-pr-456/   # mode: review
myapp-review-security/ # mode: review (audit)
```

**Best For:**
- Open source maintainers
- Code review heavy workflows
- Security auditing
- Quality-focused teams

**Commands:**
```bash
/wtm-new review/pr-123 --mode review --description "Review user auth PR"
/wtm-new review/security-audit --mode review
```

---

## Team Collaboration

### Sharing Worktree Practices

**Document Your Strategy:**

Create `WORKTREE-GUIDE.md` in your repository:
```markdown
# Our Worktree Strategy

## Naming Convention
- Feature: `<repo>-feature-<short-name>`
- Bugfix: `<repo>-bugfix-<issue-number>`

## Modes
- `main`: Production code only
- `feature`: All development work
- `bugfix`: Bug fixes only

## Workflow
1. Create feature worktree: `/wtm-new feature/name`
2. Develop and commit
3. Push and create PR
4. After merge: `/wtm-destroy ../path`
```

### Team Conventions

**Agree On:**
1. **Naming patterns**: Consistent prefixes
2. **Mode usage**: When to use each mode
3. **Cleanup policy**: When to destroy worktrees
4. **Metadata descriptions**: Level of detail

**Example Team Agreement:**
```markdown
## Team Worktree Standards

### Naming
- Always use branch name in directory: `myapp-<branch-name>`
- Replace slashes with hyphens: `feature/user-auth` → `feature-user-auth`

### Modes
- `feature` for all development
- `bugfix` for issue fixes only
- `main` reserved for production hotfixes

### Cleanup
- Destroy worktree immediately after PR merge
- Run `/wtm-list` weekly to audit active worktrees

### Descriptions
- Always include issue number if applicable
- One sentence explaining purpose
```

### CI/CD Integration

**Worktree-Aware CI:**

Each worktree can have its own CI configuration or environment:

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      # Read .ai-context.json to customize behavior
      - name: Read worktree mode
        run: |
          MODE=$(jq -r '.mode' .ai-context.json || echo "feature")
          echo "WORKTREE_MODE=$MODE" >> $GITHUB_ENV

      # Skip certain checks for experiment mode
      - name: Lint
        if: env.WORKTREE_MODE != 'experiment'
        run: npm run lint

      # Always run tests
      - name: Test
        run: npm test
```

---

## Troubleshooting

### Issue: "Branch already has a worktree"

**Symptom:**
```
Error: Branch 'feature/login' already has a worktree at /path/to/worktree
```

**Cause:** Trying to create a second worktree for the same branch

**Solution:**
```bash
# Option 1: Use the existing worktree
cd /path/to/existing/worktree

# Option 2: Destroy old worktree first
/wtm-destroy /path/to/old/worktree
/wtm-new feature/login

# Option 3: Checkout different branch in main repo
cd /path/to/main/repo
git checkout different-branch
```

### Issue: Metadata file is missing

**Symptom:** `/wtm-status` shows "no metadata"

**Solution:**
```bash
# Add metadata to existing worktree
/wtm-adopt --mode feature --description "Your description"
```

### Issue: Uncommitted changes when destroying

**Symptom:** Want to remove worktree but have uncommitted work

**Solution:**
```bash
# Option 1: Commit changes
cd /path/to/worktree
git add .
git commit -m "Save work in progress"
/wtm-destroy /path/to/worktree

# Option 2: Stash changes
cd /path/to/worktree
git stash
/wtm-destroy /path/to/worktree
# Later: git stash pop (in main repo or another worktree)

# Option 3: Proceed anyway (DESTRUCTIVE)
/wtm-destroy /path/to/worktree
# Will warn you, but can proceed
```

### Issue: Too many worktrees

**Symptom:** Can't track all your worktrees

**Solution:**
```bash
# Audit all worktrees
/wtm-list

# Identify completed work
# For each completed worktree:
/wtm-destroy ../myapp-feature-completed-thing

# Clean up stale references
git worktree prune
```

### Issue: Confused about which worktree to use

**Symptom:** Multiple worktrees, unclear which has what work

**Solution:**
```bash
# Check current worktree
/wtm-status

# List all with descriptions
/wtm-list

# Add better descriptions
/wtm-adopt --description "Clear, specific purpose"

# Clean up unclear worktrees
/wtm-destroy ../myapp-temp  # Vague names
```

### Issue: Metadata and branch don't match

**Symptom:** `.ai-context.json` shows wrong branch

**Cause:** Branch was changed after metadata creation

**Solution:**
```bash
# Re-adopt to update metadata
/wtm-adopt --description "Updated description"

# This will regenerate metadata with correct branch
```

---

## Advanced Topics

### Worktree Best Practices Summary

**Creation:**
- ✅ Use descriptive names
- ✅ Always add descriptions
- ✅ Choose appropriate mode
- ✅ Use branch prefixes for auto-mode

**Usage:**
- ✅ Run `/wtm-status` when starting work
- ✅ Use `/wtm-list` to see all work
- ✅ Keep modes consistent with work type
- ✅ Update descriptions if purpose changes

**Cleanup:**
- ✅ Destroy after PR merge
- ✅ Check for uncommitted changes first
- ✅ Run weekly audit with `/wtm-list`
- ✅ Clean up experiment worktrees promptly

### When NOT to Use Worktrees

**Use Traditional Branches If:**
- Only working on one thing at a time
- Rarely switch contexts
- Short-lived changes (< 1 hour)
- Very simple projects

**Worktrees Add Overhead For:**
- Single-file edits
- Quick typo fixes
- Documentation-only changes
- Projects with no parallel work

### Performance Considerations

**Disk Space:**
- Each worktree duplicates working tree (not `.git`)
- Source code is duplicated, git history is shared
- For large repos, worktrees can use significant disk space

**Build Artifacts:**
- Each worktree has its own `node_modules/`, `target/`, etc.
- Can use significant disk space
- Consider sharing build cache if possible

**Management:**
- More worktrees = more to track
- Recommended max: 5-10 active worktrees
- Archive or destroy unused worktrees regularly

### Integration with AI Tools

**How AI Uses Metadata:**

1. **Context Understanding:**
   - Reads `.ai-context.json` automatically
   - Understands mode semantics
   - Adjusts behavior accordingly

2. **Suggestion Style:**
   - `main`: Conservative, safe suggestions
   - `feature`: Helpful, proactive
   - `bugfix`: Focused, minimal scope
   - `experiment`: Aggressive, quick solutions
   - `review`: Analytical, critical

3. **Warnings and Checks:**
   - `main`: Warns about any changes
   - `bugfix`: Warns about scope creep
   - `experiment`: Minimal warnings
   - `review`: Suggests improvements

4. **Tool Selection:**
   - Recommends appropriate tools based on mode
   - Suggests testing strategies per mode
   - Provides mode-appropriate examples

---

## Quick Reference

### Essential Commands

```bash
# Create new worktree with metadata
/wtm-new <branch-name> [--mode <mode>] [--description "<text>"]

# List all worktrees with metadata
/wtm-list

# Show current worktree metadata
/wtm-status

# Add metadata to existing worktree
/wtm-adopt [--mode <mode>] [--description "<text>"]

# Remove worktree (preserves branch)
/wtm-destroy <worktree-path>
```

### Mode Quick Reference

| Mode | Purpose | Restrictions | AI Behavior |
|------|---------|--------------|-------------|
| `main` | Production code | Minimal changes only | Conservative |
| `feature` | Development | None | Helpful |
| `bugfix` | Bug fixes | Focused scope | Minimal scope |
| `experiment` | Prototypes | None | Aggressive |
| `review` | Code review | Read-only mindset | Analytical |

### Metadata Template

```json
{
  "worktree": "directory-name",
  "branch": "branch-name",
  "mode": "feature",
  "created": "2025-11-23T12:34:56Z",
  "description": "Purpose of worktree"
}
```

---

## Further Reading

- Git Worktree Official Docs: `git help worktree`
- Working Tree Consultant Agent: Invoke for strategic guidance
- Templates: See `templates/` directory for copy-paste templates

---

**Version:** 1.0.0
**Last Updated:** 2025-11-23
**Maintained by:** Waypoint working-tree module

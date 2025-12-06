---
name: gh-issue-lifecycle
description: How issues move through states and connect to code. Use when managing issue state transitions, linking to branches/PRs, and handling stale issues.
---

# Issue Lifecycle

State machine for GitHub issues and how they connect to code.

## State Diagram

```
                    ┌─────────────────┐
                    │  needs-triage   │ ← New issue created
                    └────────┬────────┘
                             │ triage
                    ┌────────▼────────┐
        ┌───────────│    accepted     │ ← In backlog
        │           └────────┬────────┘
        │                    │ start work
        │           ┌────────▼────────┐
        │    ┌──────│  in-progress    │ ← Active development
        │    │      └────────┬────────┘
        │    │               │ PR merged
        │    │      ┌────────▼────────┐
        │    │      │    completed    │ ← Issue resolved
        │    │      └─────────────────┘
        │    │
        │    │ blocked
        │    │      ┌─────────────────┐
        │    └─────►│     blocked     │ ← Waiting on dependency
        │           └─────────────────┘
        │
        │ needs-info
        │           ┌─────────────────┐
        └──────────►│   needs-info    │ ← Waiting for clarification
                    └─────────────────┘
```

## State Definitions

### Open States

| State | Label | Meaning |
|-------|-------|---------|
| New | `needs-triage` | Just created, not reviewed |
| Clarification | `needs-info` | Waiting on reporter |
| Backlog | `accepted` | Triaged, waiting for work |
| Active | `in-progress` | Someone is working on it |
| Blocked | `blocked` | Can't proceed |

### Closed States

| State | Reason | Comment |
|-------|--------|---------|
| Completed | Fixed/implemented | Via PR or manual |
| Duplicate | Same as another | "Duplicate of #N" |
| Won't Fix | Out of scope | Explain why |
| Invalid | Not a real issue | Cannot reproduce |
| Stale | No activity | Auto-closed after warning |

## Linking Issues to Code

### Branch Naming

When starting work on issue `#123`:

```
feat/123-short-description    # feature
fix/123-short-description     # bug fix
chore/123-short-description   # maintenance
docs/123-short-description    # documentation
```

Examples:
- `feat/42-add-dark-mode`
- `fix/123-login-timeout`
- `chore/99-update-deps`

### PR Title

Include issue number in PR title:

```
feat: add dark mode (#42)
fix: resolve login timeout (#123)
chore: update dependencies (#99)
```

### PR Description

Use closing keywords in PR body:

| Keyword | Effect |
|---------|--------|
| `Closes #123` | Auto-closes when merged |
| `Fixes #123` | Same as Closes |
| `Resolves #123` | Same as Closes |

Example PR description:
```markdown
## Summary
Add dark mode toggle to settings page.

Closes #42

## Changes
- Add theme context
- Create toggle component
- Update color variables
```

### Linking Without Closing

Reference issues without auto-close:

```
Related to #45
See also #67
Depends on #89
```

## Manual Close Reasons

When closing without PR, always comment:

### Duplicate
```bash
gh issue close 123 --comment "Duplicate of #456"
```

### Won't Fix
```bash
gh issue close 123 --comment "Closing as won't fix: [reason]"
```

### Invalid / Cannot Reproduce
```bash
gh issue close 123 --comment "Cannot reproduce with provided steps. Please reopen with more details if issue persists."
```

### Stale
```bash
gh issue close 123 --comment "Closing due to inactivity. Please reopen if still relevant."
```

## Stale Issue Handling

### Detection

Issues with no activity for N days (typically 90):

```bash
# Find stale issues
gh issue list --search "updated:<$(date -v-90d +%Y-%m-%d)"
```

### Warning Process

1. Add `stale` label
2. Comment:
   ```
   This issue has been inactive for 90 days.
   It will be closed in 30 days if there's no further activity.
   Please comment if this is still relevant.
   ```
3. Close after 30 more days if no response

### Automation (GitHub Action)

```yaml
name: Stale Issues
on:
  schedule:
    - cron: '0 0 * * *'
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          stale-issue-message: 'This issue has been inactive for 90 days.'
          days-before-stale: 90
          days-before-close: 30
          stale-issue-label: 'stale'
```

## Bulk Operations

### Close Multiple Issues

```bash
# Close all issues with label
gh issue list --label "stale" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --comment "Closing stale issue"
```

### Relabel Issues

```bash
# Add label to all issues matching query
gh issue list --search "is:open label:bug" --json number --jq '.[].number' | \
  xargs -I {} gh issue edit {} --add-label "needs-review"
```

### Transfer Issues

```bash
# Move issue to another repo
gh issue transfer 123 owner/other-repo
```

## Workflow Commands

### Start Work on Issue

```bash
# Create branch from issue
gh issue develop 123 --checkout

# Or manually
git checkout -b fix/123-description main
gh issue edit 123 --add-label "in-progress"
```

### Complete Issue via PR

```bash
# Create PR that closes issue
gh pr create --title "fix: resolve issue (#123)" --body "Closes #123"
```

### Mark as Blocked

```bash
gh issue edit 123 \
  --remove-label "in-progress" \
  --add-label "blocked"
gh issue comment 123 --body "Blocked on #456"
```

## Related

- Skill: `gh-issue-templates` - Creating well-formatted issues
- Skill: `gh-issue-triage` - Labeling and prioritization
- Agent: `gh-wrangler` - Interactive lifecycle management

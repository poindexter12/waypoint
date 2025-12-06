# Label Taxonomy Reference

Complete reference for GitHub issue labels including hex colors for consistent setup.

## Creating Labels

Use `gh label create` to set up labels:

```bash
# Type labels
gh label create "bug" --color "d73a4a" --description "Something is broken"
gh label create "feature" --color "a2eeef" --description "New functionality"
gh label create "enhancement" --color "84b6eb" --description "Improvement to existing feature"
gh label create "docs" --color "0075ca" --description "Documentation only"
gh label create "chore" --color "fef2c0" --description "Maintenance, deps, infra"

# Priority labels
gh label create "priority: critical" --color "b60205" --description "Drop everything, fix now"
gh label create "priority: high" --color "d93f0b" --description "Next up after current work"
gh label create "priority: medium" --color "fbca04" --description "Normal backlog"
gh label create "priority: low" --color "0e8a16" --description "Nice to have, someday"

# Status labels
gh label create "needs-triage" --color "ededed" --description "New, not yet categorized"
gh label create "needs-info" --color "d876e3" --description "Waiting for reporter clarification"
gh label create "accepted" --color "0e8a16" --description "Triaged and in backlog"
gh label create "in-progress" --color "1d76db" --description "Someone is working on it"
gh label create "blocked" --color "b60205" --description "Can't proceed, waiting on something"

# Common area labels (customize for your project)
gh label create "area: api" --color "c5def5" --description "API and backend"
gh label create "area: cli" --color "c5def5" --description "CLI and commands"
gh label create "area: ui" --color "c5def5" --description "User interface"
gh label create "area: docs" --color "c5def5" --description "Documentation"
gh label create "area: auth" --color "c5def5" --description "Authentication and authorization"
```

## Label Colors

### Type Labels

| Label | Hex | Preview |
|-------|-----|---------|
| bug | `#d73a4a` | Red |
| feature | `#a2eeef` | Cyan |
| enhancement | `#84b6eb` | Light blue |
| docs | `#0075ca` | Dark blue |
| chore | `#fef2c0` | Light yellow |

### Priority Labels

| Label | Hex | Visual |
|-------|-----|--------|
| priority: critical | `#b60205` | Dark red |
| priority: high | `#d93f0b` | Orange-red |
| priority: medium | `#fbca04` | Yellow |
| priority: low | `#0e8a16` | Green |

### Status Labels

| Label | Hex | Visual |
|-------|-----|--------|
| needs-triage | `#ededed` | Gray |
| needs-info | `#d876e3` | Purple |
| accepted | `#0e8a16` | Green |
| in-progress | `#1d76db` | Blue |
| blocked | `#b60205` | Dark red |

### Area Labels

| Label | Hex | Visual |
|-------|-----|--------|
| area: * | `#c5def5` | Light blue (consistent) |

## Setup Script

Save as `setup-labels.sh`:

```bash
#!/bin/bash
# Setup standard GitHub labels for issue management

set -e

echo "Creating type labels..."
gh label create "bug" --color "d73a4a" --description "Something is broken" --force
gh label create "feature" --color "a2eeef" --description "New functionality" --force
gh label create "enhancement" --color "84b6eb" --description "Improvement to existing feature" --force
gh label create "docs" --color "0075ca" --description "Documentation only" --force
gh label create "chore" --color "fef2c0" --description "Maintenance, deps, infra" --force

echo "Creating priority labels..."
gh label create "priority: critical" --color "b60205" --description "Drop everything, fix now" --force
gh label create "priority: high" --color "d93f0b" --description "Next up after current work" --force
gh label create "priority: medium" --color "fbca04" --description "Normal backlog" --force
gh label create "priority: low" --color "0e8a16" --description "Nice to have, someday" --force

echo "Creating status labels..."
gh label create "needs-triage" --color "ededed" --description "New, not yet categorized" --force
gh label create "needs-info" --color "d876e3" --description "Waiting for reporter clarification" --force
gh label create "accepted" --color "0e8a16" --description "Triaged and in backlog" --force
gh label create "in-progress" --color "1d76db" --description "Someone is working on it" --force
gh label create "blocked" --color "b60205" --description "Can't proceed, waiting on something" --force

echo "Done! Labels created."
```

## Listing Existing Labels

```bash
# List all labels
gh label list

# List with JSON output
gh label list --json name,color,description
```

## Updating Labels

```bash
# Update existing label
gh label edit "bug" --color "d73a4a" --description "Something is broken"

# Rename a label
gh label edit "old-name" --name "new-name"
```

## Deleting Labels

```bash
# Delete a label (careful!)
gh label delete "label-name" --yes
```

---
name: github-actions
description: |
  GitHub Actions CI/CD reference for workflow templates, caching strategies,
  and automation patterns. Includes homelab integration with self-hosted runners.
  Use when creating workflows, debugging CI failures, or setting up deployments.
  Triggers: github actions, ci, cd, workflow, pipeline, runner, artifact.
---

# GitHub Actions Skill

GitHub Actions CI/CD reference for workflow templates, caching, and automation patterns.

## Quick Reference

```bash
gh run list --workflow=<name>  # Recent workflow runs
gh run view <run-id>           # Detailed run output
gh run download <run-id>       # Download logs
gh workflow list               # List workflows
gh workflow run <workflow>     # Trigger workflow
gh run watch <run-id>          # Watch run in real-time
```

**Key Paths:**
- `.github/workflows/` - Workflow definitions
- `actions/` - Custom local actions

## Reference Files

Load on-demand based on task:

| Topic | File | When to Load |
|-------|------|--------------|
| Patterns & Templates | [patterns.md](references/patterns.md) | Workflow templates, caching, security |

## Workflow Structure

```yaml
name: Workflow name

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:  # Manual trigger

env:
  NODE_VERSION: '18'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
```

## Common Triggers

| Trigger | Use Case |
|---------|----------|
| `push` | Build on commits |
| `pull_request` | PR validation |
| `workflow_dispatch` | Manual trigger |
| `schedule` | Cron jobs |
| `release` | Deploy on release |

## Validation Checklist

- [ ] Workflow triggers correctly configured
- [ ] Runner selection appropriate
- [ ] Caching implemented for dependencies
- [ ] Secrets properly configured
- [ ] Permissions minimal and explicit
- [ ] Actions pinned to specific versions
- [ ] Branch/path filters correct

# Claude Development Guide for Waypoint

This document provides context and guidelines for Claude when working on the Waypoint project.

## Project Overview

**Waypoint** is a collection of Claude Code plugins organized into two categories:

- **Workflows** (`workflows/`): Operational tooling (git worktree management)
- **Technologies** (`technologies/`): Domain knowledge (Terraform, Ansible, Docker, Proxmox)

Each category is a plugin with its own `.claude-plugin/plugin.json` manifest.

## Repository Structure

```
waypoint/
├── .claude-plugin/plugin.json    # Root plugin index
├── workflows/                    # Operational tooling
│   ├── .claude-plugin/plugin.json
│   ├── agents/consultant.md
│   ├── commands/*.md
│   └── skills/working-tree/
├── technologies/                 # Domain knowledge
│   ├── .claude-plugin/plugin.json
│   ├── agents/*.md
│   └── skills/*/
└── claire/                       # Meta-tooling
    ├── .claude-plugin/plugin.json
    ├── agents/
    ├── commands/
    └── skills/
```

## Makefile Configuration

```makefile
MODULES := workflows technologies claire

workflows_PATH := workflows
technologies_PATH := technologies
claire_PATH := claire
```

## Adding Components

**Add a workflow component:**
- Agents go in `workflows/agents/`
- Commands go in `workflows/commands/`
- Skills go in `workflows/skills/`

**Add a technology:**
- Agent: `technologies/agents/my-tech.md`
- Skill: `technologies/skills/my-tech/SKILL.md`
- References: `technologies/skills/my-tech/references/`

Run `make manifest` after adding to update plugin.json files.

## Current Plugins

### workflows

Git worktree management with AI context tracking.

- **Agent**: `consultant.md`
- **Commands**: `adopt.md`, `destroy.md`, `list.md`, `new.md`, `status.md`
- **Skill**: `working-tree/`

### technologies

Domain knowledge for infrastructure tools.

- **Agents**: `terraform.md`, `ansible.md`, `docker-compose.md`, `proxmox.md`
- **Skills**: `terraform/`, `ansible/`, `docker/`, `proxmox/`

### claire

Meta-tooling for Claude Code component authoring.

- **Agents**: `coordinator.md`, `author-agent.md`, `author-command.md`
- **Commands**: `fetch-docs.md`
- **Skill**: `doc-validator/`

## Testing

```bash
make CLAUDE_DIR=/tmp/test-claude install
make CLAUDE_DIR=/tmp/test-claude check
make CLAUDE_DIR=/tmp/test-claude uninstall
```

---

Last Updated: 2025-11-27

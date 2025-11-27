# Waypoint

**Modular Claude Code plugins organized into workflows and technologies.**

Waypoint is a collection of Claude agents, commands, and skills organized into two categories:

- **Workflows**: Operational tooling that enhances how you work with Claude Code (git worktree management)
- **Technologies**: Domain knowledge for infrastructure tools (Terraform, Ansible, Docker, Proxmox)

Each category is a plugin with its own `.claude-plugin/plugin.json` manifest.

## Philosophy

- **Workflows vs Technologies**: Clear separation between operational tooling and domain knowledge
- **Modular**: Each plugin is independent and can be installed separately
- **Namespaced**: Agents, commands, and skills are organized by plugin
- **Reusable**: Clone once, use everywhere via the Claude Code plugin system

## Installation

Install Waypoint as a Claude Code plugin:

```bash
# Clone the repository
git clone git@github.com:poindexter12/waypoint.git

# The plugin system will automatically discover and load the plugins
# Just ensure the repository is accessible to Claude Code
```

Waypoint uses the Claude Code plugin system. Each subdirectory (`workflows/`, `technologies/`, `claire/`) contains a `.claude-plugin/plugin.json` manifest that defines the available agents, commands, and skills.

## Available Plugins

### Workflows

Operational tooling that enhances development workflows.

**Agents**: `consultant` - Git worktree strategy and organization
**Commands**: `/working-tree:new`, `/working-tree:status`, `/working-tree:list`, `/working-tree:destroy`, `/working-tree:adopt`
**Skills**: `working-tree` - Worktree patterns and templates

### Technologies

Domain knowledge for infrastructure tools.

**Agents**:
- `terraform` - Terraform/IaC patterns and best practices
- `ansible` - Ansible playbooks and automation
- `docker-compose` - Docker and container orchestration
- `proxmox` - Proxmox virtualization platform

**Skills**:
- `terraform` - HCL patterns, state management, Proxmox provider
- `ansible` - Playbooks, inventory, modules
- `docker` - Dockerfile, Compose, networking
- `proxmox` - VMs, LXC, storage, clustering

### Claire (Meta-Tooling)

Tools for creating and optimizing Claude Code components.

**Commands**: `/claire:fetch-docs`
**Agents**: `coordinator`, `author-agent`, `author-command`
**Skills**: `doc-validator`

## Directory Structure

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
│   ├── agents/*.md               # terraform, ansible, docker, proxmox
│   └── skills/*/                 # Per-technology skills
└── claire/                       # Meta-tooling
    ├── .claude-plugin/plugin.json
    ├── agents/
    ├── commands/
    └── skills/
```

## Makefile Reference

The Makefile provides tools for managing plugin manifests and versions.

### Targets

| Target | Description |
|--------|-------------|
| `help` | Show all available commands (default) |
| `manifest` | Update plugin.json files from directory contents |
| `version V=x.y.z` | Bump version in all plugin.json files |
| `changelog-preview` | Show commits since last version tag |
| `clean` | Remove build artifacts |

### Examples

```bash
# Update all plugin.json manifests from directory contents
make manifest

# Bump all versions to 1.2.0
make version V=1.2.0

# Preview unreleased changes for changelog
make changelog-preview
```

## Development

### Adding Components

**Add a new workflow agent/command:**
- Add agent to `workflows/agents/`
- Add commands to `workflows/commands/`
- Add skill (if needed) to `workflows/skills/`

**Add a new technology:**
- Add agent to `technologies/agents/my-tech.md`
- Add skill to `technologies/skills/my-tech/SKILL.md`
- Add references to `technologies/skills/my-tech/references/`

Then run `make manifest` to update plugin.json files.

### Plugin Structure

Each plugin category follows this pattern:

```
plugin-category/
├── .claude-plugin/
│   └── plugin.json      # Plugin manifest (auto-updated by make manifest)
├── agents/
│   └── *.md            # Agent definitions
├── commands/
│   └── *.md            # Command definitions (workflows only)
└── skills/
    └── skill-name/     # Skill directories
        ├── SKILL.md    # Required: skill definition
        ├── REFERENCE.md # Optional: detailed documentation
        └── references/ # Optional: additional docs
```

### Slash Command and Agent File Format

**Slash Command Files** (`commands/*.md`) use YAML frontmatter with these allowed fields:

- `description`: Brief description of the command (defaults to first line of prompt)
- `argument-hint`: Arguments expected, shown during auto-completion (e.g., `<branch> [--mode <mode>]`)
- `allowed-tools`: List of tools the command can use (inherits from conversation if not specified)
- `model`: Specific model to use (inherits from conversation if not specified)
- `disable-model-invocation`: Prevent SlashCommand tool from calling this command
- Additional custom fields as needed (e.g., `agent` for delegation)

**Agent Files** (`agents/*.md`) use YAML frontmatter with these fields:

- `name` (required): Unique identifier using lowercase letters and hyphens
- `description` (required): Natural language description of the agent's purpose
- `tools` (optional): Comma-separated list of specific tools (inherits all if omitted)
- `model` (optional): Model alias (`sonnet`, `opus`, `haiku`) or `inherit` (defaults to configured subagent model)
- `permissionMode` (optional): Permission handling (`default`, `acceptEdits`, `bypassPermissions`, `plan`, `ignore`)
- `skills` (optional): Comma-separated list of skill names to auto-load

**Skill Files** (`skills/skill-name/SKILL.md`) use YAML frontmatter with these fields:

- `name` (required): Unique identifier using lowercase letters and hyphens (max 64 chars)
- `description` (required): Natural language description including trigger keywords (max 1024 chars)
- `allowed-tools` (optional): Comma-separated list of tools the skill can use

Example slash command:
```markdown
---
description: Create a new git worktree with AI context
argument-hint: <branch> [--mode <mode>] [--description "<text>"]
agent: working-tree-manager
---

Command instructions here...
```

Example agent:
```markdown
---
name: working-tree-manager
description: Manages git worktrees with AI context tracking
tools: Bash, Read, Write, Grep
model: sonnet
---

You are a git worktree manager. When invoked...
```

Example skill:
```markdown
---
name: doc-validator
description: Validate documentation files for completeness, accuracy, and consistency. Use when checking README files, API docs, or documentation quality.
allowed-tools: Read, Grep, Glob
---

# Documentation Validator Skill

Validates documentation files to ensure they are complete...
```

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Add or improve a module
4. Run `make manifest` to update plugin.json files
5. Submit a pull request

## License

MIT License - See [LICENSE](./LICENSE) for details.

## Credits

Created by [Joe Seymour](https://github.com/poindexter12)

Designed for use with [Claude Code](https://claude.com/claude-code) and compatible AI coding tools.

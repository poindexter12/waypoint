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
- **Reusable**: Clone once, use everywhere via symlinks or copies
- **Maintainable**: Simple Makefile-based installation and management

## Quick Start

```bash
# Clone the repository
git clone git@github.com:poindexter12/waypoint.git
cd waypoint

# Install everything to ~/.claude/
make install

# Or install a specific module
make install workflows

# Or install to a project directory
make CLAUDE_DIR=/path/to/project/.claude install

# Copy files instead of symlinking
make MODE=copy install

# Verify installation
make check

# See all available commands
make help
```

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

## Installation

### Requirements

- Git
- Make
- A Claude-compatible AI tool (Claude Code, Cursor, etc.)

### Installation Options

Waypoint supports two installation modes:

1. **Symlink mode** (default): Creates symbolic links from this repository to your Claude directory
   - Changes to this repo are immediately reflected
   - Good for development and testing

2. **Copy mode**: Copies files to your Claude directory
   - Changes require reinstallation
   - Good for stable, production use

### Installation Targets

```bash
# Install all modules
make install

# Install specific module
make install working-tree

# Install to custom directory (e.g., project-specific)
make CLAUDE_DIR=./.claude install

# Use copy mode instead of symlinks
make MODE=copy install

# Combine options
make CLAUDE_DIR=/custom/path MODE=copy install workflows
```

### Directory Structure

**Repository structure:**

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

**After installation**, your Claude directory will look like:

```
~/.claude/
├── agents/
│   ├── workflows/
│   │   └── consultant.md
│   ├── technologies/
│   │   ├── terraform.md
│   │   ├── ansible.md
│   │   ├── docker-compose.md
│   │   └── proxmox.md
│   └── claire/
│       └── *.md
├── commands/
│   ├── workflows/
│   │   └── *.md (adopt, destroy, list, new, status)
│   └── claire/
│       └── fetch-docs.md
└── skills/
    ├── workflows/
    │   └── working-tree/
    ├── technologies/
    │   └── */ (terraform, ansible, docker, proxmox)
    └── claire/
        └── doc-validator/
```

## Makefile Reference

### Targets

| Target | Description |
|--------|-------------|
| `help` | Show all available commands (default) |
| `install [MODULE]` | Install all or specific module |
| `uninstall [MODULE]` | Remove installed modules |
| `check [MODULE]` | Verify installation is correct |
| `fix [MODULE]` | Repair broken or missing symlinks |
| `list [MODULE]` | Show what would be installed (dry-run) |
| `clean` | Remove local build artifacts |

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_DIR` | `~/.claude` | Installation directory |
| `MODE` | `symlink` | Installation mode (`symlink` or `copy`) |

### Examples

```bash
# Preview what would be installed
make list

# Install everything with default settings
make install

# Install to project directory
make CLAUDE_DIR=$(pwd)/.claude install

# Copy instead of symlink
make MODE=copy install

# Check if installation is working
make check

# Fix broken symlinks
make fix

# Uninstall everything
make uninstall

# Uninstall specific module
make uninstall working-tree
```

## Testing

Waypoint includes a comprehensive test suite to ensure all functionality works correctly.

### Requirements

- Python 3.7+
- [uv](https://github.com/astral-sh/uv) (will be installed automatically if not present)

### Running Tests

```bash
# Run the full test suite
make -f Makefile.test test

# Set up test environment only
make -f Makefile.test setup

# Clean up test environment
make -f Makefile.test clean
```

### What Gets Tested

The test suite validates:

- ✅ **Installation**: Both symlink and copy modes
- ✅ **Module-specific operations**: Installing individual modules
- ✅ **Symlink targets**: Correct source file linking
- ✅ **Check command**: Validates installations and detects broken links
- ✅ **Uninstall**: Complete removal of files and directories
- ✅ **Fix command**: Repairs missing files and broken symlinks
- ✅ **Idempotency**: Operations can be run multiple times safely
- ✅ **Custom directories**: Non-default CLAUDE_DIR locations

### Test Output

The test suite provides detailed output:

```
======================================================================
Waypoint Test Suite
======================================================================

test_check_broken_symlink (__main__.TestCheck) ... ok
test_check_missing_installation (__main__.TestCheck) ... ok
test_check_valid_installation (__main__.TestCheck) ... ok
test_install_copy_mode (__main__.TestCopyInstallation) ... ok
...

----------------------------------------------------------------------
Ran 15 tests in 2.341s

OK
======================================================================
✓ All tests passed
======================================================================
```

### Test Environment

- Tests run in isolated temporary directories (`/tmp/waypoint-tests`)
- All test artifacts are automatically cleaned up
- Tests use `uv` and a virtual environment to ensure isolation
- No modifications are made to your actual `~/.claude/` directory

### Writing New Tests

When adding new modules or features, add corresponding tests to `tests/test_waypoint.py`. Follow the existing test patterns:

```python
class TestNewFeature(WaypointTestCase):
    """Test description."""

    def test_specific_behavior(self):
        """Test that specific behavior works correctly."""
        # Test implementation
        pass
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

### Testing Changes

```bash
# Install to a test directory
make CLAUDE_DIR=/tmp/test-claude install

# Check installation
make CLAUDE_DIR=/tmp/test-claude check

# Clean up
make CLAUDE_DIR=/tmp/test-claude uninstall
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

## Troubleshooting

### Broken Symlinks

If symlinks are broken (e.g., you moved the waypoint directory):

```bash
make fix
```

### Installation Not Detected

Verify installation status:

```bash
make check
```

If files are missing, reinstall:

```bash
make install
```

### Symlinks vs Copies

If you need to move the waypoint repository:

1. **With symlinks**: Run `make fix` after moving
2. **With copies**: You'll need to reinstall with `make install`

Consider using copy mode if you plan to move the repository frequently.

### Module Not Loading in Claude

1. Verify installation: `make check`
2. Check Claude is looking in the right directory
3. Restart Claude Code if needed
4. Check file permissions: `ls -la ~/.claude/agents/working-tree/`

### Permission Denied

If you get permission errors:

```bash
# Fix permissions on Claude directory
chmod -R u+w ~/.claude/

# Reinstall
make install
```

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Add or improve a module
4. Test thoroughly with `make check`
5. Submit a pull request

## License

MIT License - See [LICENSE](./LICENSE) for details.

## Credits

Created by [Joe Seymour](https://github.com/poindexter12)

Designed for use with [Claude Code](https://claude.com/claude-code) and compatible AI coding tools.

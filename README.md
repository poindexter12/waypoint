# Waypoint

**Modular, reusable Claude Code configurations for common development workflows.**

Waypoint is a collection of Claude agents, commands, and skills that can be installed globally or per-project, providing consistent AI-assisted tooling across your development environment. Each module is self-contained, well-documented, and easy to install via a simple Makefile.

## Philosophy

- **Modular**: Each module is independent and can be installed separately
- **Namespaced**: Agents, commands, and skills are organized by module (e.g., `@working-tree:manager`)
- **Reusable**: Clone once, use everywhere via symlinks or copies
- **Maintainable**: Simple Makefile-based installation and management
- **Project-agnostic**: Install globally to `~/.claude/` or per-project as needed

## Quick Start

```bash
# Clone the repository
git clone git@github.com:poindexter12/waypoint.git
cd waypoint

# Install everything to ~/.claude/
make install

# Or install a specific module
make install working-tree

# Or install to a project directory
make CLAUDE_DIR=/path/to/project/.claude install

# Copy files instead of symlinking
make MODE=copy install

# Verify installation
make check

# See all available commands
make help
```

## Available Modules

### [working-tree](./working-tree/README.md)

Git worktree management with AI context tracking. Creates isolated development environments with structured metadata that helps Claude understand your workflow.

**Commands**: `/wtm-new`, `/wtm-status`, `/wtm-list`, `/wtm-destroy`, `/wtm-adopt`
**Agents**: `@working-tree:manager`

See [working-tree/README.md](./working-tree/README.md) for detailed documentation.

### [claire](./claire/README.md)

Meta-agent for creating and optimizing Claude Code components (agents, commands, and skills). Automatically fetches latest official documentation to ensure best practices.

**Commands**: `/claire-fetch-docs`
**Agents**: `@claire:optimizer`
**Skills**: `doc-validator`

See [claire/README.md](./claire/README.md) for detailed documentation.

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
make CLAUDE_DIR=/custom/path MODE=copy install working-tree
```

### Directory Structure

After installation, your Claude directory will look like:

```
~/.claude/
├── agents/
│   ├── working-tree/
│   │   └── manager.md
│   └── claire/
│       └── optimizer.md
├── commands/
│   ├── working-tree/
│   │   ├── new.md
│   │   ├── status.md
│   │   ├── list.md
│   │   ├── destroy.md
│   │   └── adopt.md
│   └── claire/
│       └── fetch-docs.md
└── skills/
    └── claire/
        └── doc-validator/
            ├── SKILL.md
            └── REFERENCE.md
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

### Adding a New Module

1. Create a directory for your module: `mkdir my-module`
2. Add subdirectories as needed: `mkdir my-module/agents my-module/commands my-module/skills`
3. Create agent/command files as `.md` files in the respective directories
4. Create skills as subdirectories with a `SKILL.md` file: `my-module/skills/skill-name/SKILL.md`
5. Create `my-module/README.md` documenting your module
6. Add module to `MODULES` list in root `Makefile`
7. Test installation: `make install my-module`

That's it! No module-specific Makefile needed - the root Makefile handles everything.

### Module Structure

```
my-module/
├── README.md             # Module documentation
├── agents/
│   └── *.md             # Agent definitions (optional)
├── commands/
│   └── *.md             # Command definitions (optional)
└── skills/
    └── skill-name/      # Skill directories (optional)
        ├── SKILL.md     # Required: skill definition
        ├── REFERENCE.md # Optional: detailed documentation
        ├── scripts/     # Optional: helper scripts
        └── templates/   # Optional: file templates
```

Modules can have agents, commands, skills, or any combination. The root Makefile automatically discovers and installs all files from these directories.

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

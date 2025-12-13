# Plugin Structure Validation

File and directory structure conventions for Claude Code plugins.

## Standard Directory Layout

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (preferred location)
├── agents/                  # Agent files (optional)
│   ├── agent-1.md
│   └── agent-2.md
├── commands/                # Command files (optional)
│   ├── command-1.md
│   └── command-2.md
├── skills/                  # Skill directories (optional)
│   ├── skill-1/
│   │   ├── SKILL.md        # Required skill manifest
│   │   ├── REFERENCE.md    # Optional reference docs
│   │   └── references/     # Optional reference materials
│   └── skill-2/
│       └── SKILL.md
├── README.md                # Plugin documentation
└── LICENSE                  # License file
```

## Directory Conventions

### .claude-plugin/
- **Purpose**: Plugin metadata and configuration
- **Required**: Yes (or plugin.json in root)
- **Contents**:
  - `plugin.json` - Plugin manifest (required)
  - Other config files (optional)

### agents/
- **Purpose**: Agent markdown files
- **Required**: No (only if plugin has agents)
- **Naming**: Descriptive names, lowercase-with-hyphens
- **Extensions**: `.md` only
- **Examples**:
  - `consultant.md`
  - `working-tree-optimizer.md`
  - `claire-coordinator.md`

### commands/
- **Purpose**: Command markdown files
- **Required**: No (only if plugin has commands)
- **Naming**: Usually action-oriented, lowercase-with-hyphens
- **Extensions**: `.md` only
- **Examples**:
  - `new.md`
  - `list.md`
  - `fetch-docs.md`

### skills/
- **Purpose**: Skill directories with knowledge/templates
- **Required**: No (only if plugin has skills)
- **Structure**: Each skill is a directory
- **Required file**: `SKILL.md` in each skill directory
- **Examples**:
  - `skills/working-tree/SKILL.md`
  - `skills/doc-validator/SKILL.md`

## File Naming Conventions

### Agents
- **Format**: `descriptive-name.md`
- **Pattern**: `^[a-z][a-z0-9-]*\.md$`
- **Guidelines**:
  - Use noun or role names: `consultant`, `optimizer`, `coordinator`
  - Include plugin prefix for clarity: `claire-coordinator`
  - Avoid generic names: `helper`, `manager`, `utils`

### Commands
- **Format**: `action-name.md`
- **Pattern**: `^[a-z][a-z0-9-]*\.md$`
- **Guidelines**:
  - Use verb-based names: `new`, `destroy`, `list`, `status`
  - Keep short and memorable
  - Match CLI conventions

### Skills
- **Format**: `skill-name/` (directory)
- **Pattern**: `^[a-z][a-z0-9-]*$` (no extension)
- **Required**: `SKILL.md` file inside
- **Guidelines**:
  - Use descriptive directory names
  - Must contain `SKILL.md` (uppercase)
  - Can include additional reference files

## Path Conventions

### Relative Paths (Required)
All paths in plugin.json must be relative:
```json
{
  "agents": ["./agents/consultant.md"],
  "commands": ["./commands/new.md"],
  "skills": ["./skills/working-tree"]
}
```

### Absolute Paths (Invalid)
```json
{
  "agents": ["/Users/joe/plugins/agent.md"],  // ✗ Absolute path
  "skills": ["~/plugins/skill"]  // ✗ Home directory expansion
}
```

### Path Separators
- Use forward slash `/` (works on all platforms)
- Avoid backslash `\` (Windows-specific)

### Trailing Slashes
- **Files**: No trailing slash
- **Directories**: No trailing slash (even for skills)

```json
{
  "agents": ["./agents/agent.md"],    // ✓ Correct
  "skills": ["./skills/my-skill"]     // ✓ Correct (no trailing /)
}
```

## File Reference Validation

### Check Files Exist
For each reference in plugin.json, validate the file/directory exists:

```bash
# Validate agents
jq -r '.agents[]?' plugin.json | while read path; do
    if [ -f "$path" ]; then
        echo "✓ Agent: $path"
    else
        echo "✗ Missing agent: $path"
    fi
done

# Validate commands
jq -r '.commands[]?' plugin.json | while read path; do
    if [ -f "$path" ]; then
        echo "✓ Command: $path"
    else
        echo "✗ Missing command: $path"
    fi
done

# Validate skills
jq -r '.skills[]?' plugin.json | while read path; do
    if [ -d "$path" ] && [ -f "$path/SKILL.md" ]; then
        echo "✓ Skill: $path"
    elif [ -d "$path" ]; then
        echo "⚠ Skill directory exists but missing SKILL.md: $path"
    else
        echo "✗ Missing skill: $path"
    fi
done
```

### Check for Orphaned Files
Find files that exist but aren't referenced in plugin.json:

```bash
# Find orphaned agents
find agents -name "*.md" -type f | while read file; do
    grep -q "\"$file\"" plugin.json || echo "⚠ Orphaned agent: $file"
done

# Find orphaned commands
find commands -name "*.md" -type f | while read file; do
    grep -q "\"$file\"" plugin.json || echo "⚠ Orphaned command: $file"
done

# Find orphaned skills
find skills -maxdepth 1 -mindepth 1 -type d | while read dir; do
    skill_path="./${dir}"
    grep -q "\"$skill_path\"" plugin.json || echo "⚠ Orphaned skill: $skill_path"
done
```

## Common Structural Issues

### Issue: Incorrect manifest location
```
plugin-name/
├── plugin.json         # ⚠ Legacy location
├── .claude-plugin/     # Preferred location but empty
```

**Fix:** Move plugin.json to .claude-plugin/
```bash
mkdir -p .claude-plugin
mv plugin.json .claude-plugin/plugin.json
```

### Issue: Missing SKILL.md
```
skills/
└── my-skill/
    ├── REFERENCE.md    # ✗ Has reference but no SKILL.md
    └── examples/
```

**Fix:** Create SKILL.md
```bash
touch skills/my-skill/SKILL.md
# Add required frontmatter and content
```

### Issue: Inconsistent casing
```
agents/
├── MyAgent.md          # ✗ Capital letters
├── another_agent.md    # ✗ Underscores
└── proper-agent.md     # ✓ Correct
```

**Fix:** Rename to lowercase-with-hyphens
```bash
mv agents/MyAgent.md agents/my-agent.md
mv agents/another_agent.md agents/another-agent.md
```

### Issue: Absolute paths in plugin.json
```json
{
  "agents": ["/full/path/to/agent.md"]
}
```

**Fix:** Use relative paths
```json
{
  "agents": ["./agents/agent.md"]
}
```

### Issue: Wrong file extension
```
commands/
├── my-command.txt      # ✗ Wrong extension
└── other-command.md    # ✓ Correct
```

**Fix:** Use `.md` extension
```bash
mv commands/my-command.txt commands/my-command.md
```

## Validation Checklist

### Manifest Location
- [ ] plugin.json exists in `.claude-plugin/` OR root (not both)
- [ ] `.claude-plugin/plugin.json` preferred over root location

### Directory Structure
- [ ] `agents/` directory exists if agents defined
- [ ] `commands/` directory exists if commands defined
- [ ] `skills/` directory exists if skills defined
- [ ] All directories follow naming conventions

### File References
- [ ] All agent files referenced in plugin.json exist
- [ ] All command files referenced in plugin.json exist
- [ ] All skill directories referenced in plugin.json exist
- [ ] All skill directories contain `SKILL.md`
- [ ] No broken file references

### File Naming
- [ ] All agent files use lowercase-with-hyphens
- [ ] All command files use lowercase-with-hyphens
- [ ] All skill directories use lowercase-with-hyphens
- [ ] All markdown files use `.md` extension
- [ ] Skill manifests named exactly `SKILL.md` (uppercase)

### Path Format
- [ ] All paths in plugin.json are relative
- [ ] All paths start with `./`
- [ ] No trailing slashes on paths
- [ ] Forward slashes used (not backslashes)

### Orphaned Files
- [ ] No agent files exist that aren't referenced
- [ ] No command files exist that aren't referenced
- [ ] No skill directories exist that aren't referenced
- [ ] Check for stale/abandoned files

## Directory Permissions

All plugin files should be readable:
```bash
# Check permissions
find . -type f -name "*.md" ! -perm -u+r -ls
find . -name "plugin.json" ! -perm -u+r -ls

# Fix permissions if needed
chmod 644 agents/*.md commands/*.md
chmod 644 .claude-plugin/plugin.json
chmod 755 skills/*/  # Directories need execute
```

## Complete Validation Script

```bash
#!/bin/bash
# Validate plugin structure

PLUGIN_ROOT="."
ERRORS=0

# Check manifest exists
if [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
    MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
elif [ -f "$PLUGIN_ROOT/plugin.json" ]; then
    MANIFEST="$PLUGIN_ROOT/plugin.json"
    echo "⚠ Using legacy manifest location (plugin.json)"
else
    echo "✗ No plugin.json found"
    exit 1
fi

# Validate referenced files exist
cd "$PLUGIN_ROOT"

jq -r '.agents[]?' "$MANIFEST" | while read path; do
    [ -f "$path" ] || { echo "✗ Missing agent: $path"; ((ERRORS++)); }
done

jq -r '.commands[]?' "$MANIFEST" | while read path; do
    [ -f "$path" ] || { echo "✗ Missing command: $path"; ((ERRORS++)); }
done

jq -r '.skills[]?' "$MANIFEST" | while read path; do
    [ -d "$path" ] || { echo "✗ Missing skill dir: $path"; ((ERRORS++)); }
    [ -f "$path/SKILL.md" ] || { echo "✗ Missing SKILL.md: $path"; ((ERRORS++)); }
done

[ $ERRORS -eq 0 ] && echo "✓ Structure validation passed" || echo "✗ Found $ERRORS errors"
exit $ERRORS
```

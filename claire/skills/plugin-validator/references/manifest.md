# Plugin Manifest Validation

Detailed rules for validating `plugin.json` files in Claude Code plugins.

## File Location

Plugin manifest can be in one of two locations:
- **Preferred**: `.claude-plugin/plugin.json`
- **Legacy**: `plugin.json` (root of plugin directory)

Only one should exist. If both exist, `.claude-plugin/plugin.json` takes precedence.

## Required Fields

### name
- **Type**: string
- **Format**: lowercase-with-hyphens
- **Pattern**: `^[a-z][a-z0-9-]*$`
- **Example**: `"claire"`, `"working-tree-tools"`
- **Validation**: Must be unique across installed plugins

### description
- **Type**: string
- **Format**: Natural language, concise
- **Length**: 20-200 characters recommended
- **Example**: `"Git worktree management with AI metadata integration"`
- **Validation**: No empty strings, should be descriptive

### version
- **Type**: string
- **Format**: Semantic versioning (semver)
- **Pattern**: `^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$`
- **Examples**: `"1.0.0"`, `"2.1.3"`, `"1.0.0-beta.1"`
- **Validation**: Must parse as valid semver

## Optional Fields

### agents
- **Type**: array of strings
- **Format**: Relative paths to agent markdown files
- **Pattern**: `"./agents/*.md"` or `"./path/to/agent.md"`
- **Example**: `["./agents/consultant.md", "./agents/optimizer.md"]`
- **Validation**:
  - All paths must be relative (start with `./`)
  - All referenced files must exist
  - Files must end with `.md`
  - No duplicates

### commands
- **Type**: array of strings
- **Format**: Relative paths to command markdown files
- **Pattern**: `"./commands/*.md"`
- **Example**: `["./commands/new.md", "./commands/destroy.md"]`
- **Validation**: Same as agents

### skills
- **Type**: array of strings
- **Format**: Relative paths to skill directories
- **Pattern**: `"./skills/skill-name"` (no trailing slash)
- **Example**: `["./skills/working-tree", "./skills/doc-validator"]`
- **Validation**:
  - All paths must be relative (start with `./`)
  - All referenced directories must exist
  - Each directory should contain `SKILL.md`
  - No trailing slashes
  - No duplicates

### repository
- **Type**: string
- **Format**: URL to repository
- **Example**: `"https://github.com/user/repo"`
- **Validation**: Should be valid URL (http/https)

### license
- **Type**: string
- **Format**: SPDX license identifier or "UNLICENSED"
- **Examples**: `"MIT"`, `"Apache-2.0"`, `"GPL-3.0"`
- **Validation**: Optional but recommended

### keywords
- **Type**: array of strings
- **Example**: `["claude-code", "git", "worktree"]`
- **Validation**: All strings, no empty entries

## JSON Syntax Rules

### Encoding
- UTF-8 encoding required
- No BOM (Byte Order Mark)

### Formatting
- Proper JSON structure (no trailing commas)
- Consistent indentation (2 or 4 spaces recommended)
- No comments (JSON doesn't support comments)

### Special Characters
- Use `\"` for quotes in strings
- Use `\\` for backslashes
- Use `/` or `\/` for forward slashes (both valid)

## Common Errors

### Invalid JSON
```json
{
  "name": "my-plugin",
  "version": "1.0.0",  // ✗ Comments not allowed
  "description": "Test",  // ✗ Trailing comma on last item
}
```

**Fix:**
```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Test"
}
```

### Invalid Semver
```json
{
  "version": "1.0"  // ✗ Missing patch version
}
{
  "version": "v1.0.0"  // ✗ Should not include 'v' prefix
}
```

**Fix:**
```json
{
  "version": "1.0.0"
}
```

### Absolute Paths
```json
{
  "agents": ["/Users/joe/plugin/agents/agent.md"]  // ✗ Absolute path
}
```

**Fix:**
```json
{
  "agents": ["./agents/agent.md"]
}
```

### Trailing Slashes
```json
{
  "skills": ["./skills/my-skill/"]  // ✗ Trailing slash
}
```

**Fix:**
```json
{
  "skills": ["./skills/my-skill"]
}
```

## Validation Commands

### Check JSON syntax
```bash
python3 -m json.tool plugin.json > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

### Verify required fields
```bash
# Check for required fields
jq -e '.name and .description and .version' plugin.json
```

### Validate semver
```bash
# Extract version and check format
VERSION=$(jq -r '.version' plugin.json)
echo "$VERSION" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$' && echo "Valid semver" || echo "Invalid semver"
```

### Check file references
```bash
# Verify all agents exist
jq -r '.agents[]?' plugin.json | while read agent; do
    test -f "$agent" && echo "✓ $agent" || echo "✗ $agent MISSING"
done

# Verify all commands exist
jq -r '.commands[]?' plugin.json | while read cmd; do
    test -f "$cmd" && echo "✓ $cmd" || echo "✗ $cmd MISSING"
done

# Verify all skills exist
jq -r '.skills[]?' plugin.json | while read skill; do
    test -d "$skill" && echo "✓ $skill" || echo "✗ $skill MISSING"
done
```

## Complete Example

```json
{
  "name": "waypoint-workflows",
  "description": "Git worktree management with AI context tracking",
  "version": "1.2.3",
  "repository": "https://github.com/poindexter12/waypoint",
  "license": "MIT",
  "keywords": [
    "claude-code",
    "git",
    "worktree",
    "workflow"
  ],
  "agents": [
    "./agents/consultant.md"
  ],
  "commands": [
    "./commands/new.md",
    "./commands/list.md",
    "./commands/status.md",
    "./commands/destroy.md",
    "./commands/adopt.md"
  ],
  "skills": [
    "./skills/working-tree"
  ]
}
```

## Checklist

- [ ] File is valid JSON (no syntax errors)
- [ ] `name` field present and valid format
- [ ] `description` field present and descriptive
- [ ] `version` field present and valid semver
- [ ] All array fields are proper arrays
- [ ] No duplicate entries in arrays
- [ ] All file paths are relative
- [ ] All referenced files/directories exist
- [ ] No trailing slashes on directory paths
- [ ] No trailing commas
- [ ] Proper UTF-8 encoding

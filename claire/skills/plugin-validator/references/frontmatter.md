# Frontmatter Validation

YAML frontmatter validation rules for Claude Code agents and commands.

## Location

Frontmatter appears at the beginning of agent and command markdown files:
- **Agents**: `agents/*.md`
- **Commands**: `commands/*.md`

## Format

```yaml
---
name: component-name
description: Component description
optional-field: value
---
```

Frontmatter is delimited by `---` on separate lines. Must be the first content in the file (no blank lines before opening `---`).

## Required Fields

### name
- **Type**: string
- **Format**: lowercase-with-hyphens
- **Pattern**: `^[a-z][a-z0-9-]*$`
- **Examples**:
  - `"consultant"` (agent)
  - `"working-tree-new"` (command)
  - `"claire-coordinator"` (agent with prefix)
- **Validation**:
  - Must start with lowercase letter
  - Only lowercase letters, numbers, hyphens
  - Should be unique within plugin
  - Commands often include plugin prefix

### description
- **Type**: string
- **Format**: Natural language, concise
- **Length**: 50-300 characters recommended
- **Examples**:
  - `"Strategic guidance for git worktree organization"`
  - `"Create new git worktree with AI metadata"`
- **Validation**:
  - Should clearly explain purpose
  - Should mention key triggers or use cases
  - Can include trigger examples
  - No empty strings

## Optional Fields

### tools
- **Type**: string (comma-separated)
- **Format**: `"Tool1, Tool2, Tool3"`
- **Valid Tools**:
  - `Read` - Read files
  - `Write` - Write files
  - `Edit` - Edit files
  - `Bash` - Execute bash commands
  - `Grep` - Search file contents
  - `Glob` - Find files by pattern
  - `AskUserQuestion` - Prompt user
- **Examples**:
  - `"Read, Bash"` (minimal read + execute)
  - `"Read, Write, Edit, Bash"` (file operations)
  - Omitted = inherits all tools
- **Validation**:
  - Comma-separated list
  - No spaces after commas (optional but recommended)
  - Tool names must match valid set
  - Should use minimal required set

### model
- **Type**: string (enum)
- **Valid Values**:
  - `"sonnet"` - Claude Sonnet (balanced)
  - `"opus"` - Claude Opus (powerful)
  - `"haiku"` - Claude Haiku (fast)
  - `"inherit"` - Inherit from parent
- **Default**: If omitted, inherits from system
- **Examples**: `"sonnet"`, `"opus"`
- **Validation**: Must be one of valid values

### permissionMode
- **Type**: string (enum)
- **Valid Values**:
  - `"default"` - Standard permission checking
  - `"acceptEdits"` - Auto-accept edit suggestions
  - `"bypassPermissions"` - Skip permission checks
  - `"plan"` - Plan mode (no execution)
  - `"ignore"` - Ignore permission system
- **Default**: `"default"`
- **Validation**: Must be one of valid values
- **Security**: Use with caution (especially bypass modes)

### skills
- **Type**: string (comma-separated)
- **Format**: `"skill-name-1, skill-name-2"`
- **Examples**: `"working-tree-guide, git-patterns"`
- **Validation**:
  - Comma-separated list
  - Skill names should exist in plugin or installed plugins
  - No path separators (just names)

### aliases
- **Type**: array of strings (commands only)
- **Format**: YAML array
- **Example**:
  ```yaml
  aliases:
    - wt:new
    - worktree:create
  ```
- **Validation**:
  - Only used in command files
  - Each alias must be unique
  - Follow command naming conventions

## YAML Syntax Rules

### Encoding
- UTF-8 encoding
- No BOM

### Indentation
- Use spaces (not tabs)
- Consistent indentation (2 spaces recommended)

### Strings
- Can be quoted or unquoted
- Use quotes if contains special characters: `: { } [ ] , & * # ? | - < > = ! % @ \`
- Multi-line strings use `|` or `>`

### Arrays
- Inline: `["item1", "item2"]`
- Block style:
  ```yaml
  field:
    - item1
    - item2
  ```

### Comments
- Use `#` for comments
- Comments allowed in frontmatter (unlike JSON)

## Common Errors

### Missing Delimiters
```yaml
name: my-agent
description: Test
```
**Fix:** Add `---` delimiters
```yaml
---
name: my-agent
description: Test
---
```

### Invalid Field Names
```yaml
---
Name: my-agent  # ✗ Capital N
DESCRIPTION: test  # ✗ All caps
---
```
**Fix:** Use exact field names (lowercase)
```yaml
---
name: my-agent
description: test
---
```

### Invalid Tools Format
```yaml
---
tools: ["Read", "Write"]  # ✗ Array format (use string)
tools: Read; Write  # ✗ Semicolon separator
---
```
**Fix:** Use comma-separated string
```yaml
---
tools: Read, Write
---
```

### Invalid Model Value
```yaml
---
model: claude-sonnet  # ✗ Wrong value
model: Sonnet  # ✗ Capital S
---
```
**Fix:** Use exact enum value
```yaml
---
model: sonnet
---
```

### Inconsistent Indentation
```yaml
---
name: test
  description: bad  # ✗ Unexpected indentation
tools: Read
---
```
**Fix:** Consistent indentation
```yaml
---
name: test
description: good
tools: Read
---
```

## Validation Commands

### Extract frontmatter
```bash
# Get frontmatter (between first two --- lines)
sed -n '/^---$/,/^---$/p' agent.md | head -n -1 | tail -n +2
```

### Validate YAML syntax
```bash
# Extract and validate YAML
sed -n '/^---$/,/^---$/p' agent.md | head -n -1 | tail -n +2 | python3 -c "import yaml, sys; yaml.safe_load(sys.stdin)"
```

### Check required fields
```bash
# Check for name and description
sed -n '/^---$/,/^---$/p' agent.md | grep -q "^name:" && echo "✓ name" || echo "✗ name missing"
sed -n '/^---$/,/^---$/p' agent.md | grep -q "^description:" && echo "✓ description" || echo "✗ description missing"
```

### Validate tools list
```bash
# Extract tools and check format
TOOLS=$(sed -n '/^---$/,/^---$/p' agent.md | grep "^tools:" | cut -d: -f2- | tr -d ' ')
echo "$TOOLS" | grep -q '^[A-Za-z,]*$' && echo "✓ valid format" || echo "✗ invalid format"
```

## Complete Examples

### Minimal Agent
```yaml
---
name: simple-agent
description: A simple agent with minimal configuration
---
```

### Full-Featured Agent
```yaml
---
name: advanced-agent
description: Advanced agent with all features configured, including tool restrictions and model selection
tools: Read, Write, Bash, Grep
model: sonnet
permissionMode: default
skills: helper-skill, another-skill
---
```

### Command with Aliases
```yaml
---
name: working-tree-new
description: Create a new git worktree with AI metadata tracking. Supports custom modes and descriptions.
aliases:
  - wt:new
  - worktree:create
tools: Read, Write, Bash
---
```

## Field Validation Matrix

| Field | Required | Type | Valid Values | Default |
|-------|----------|------|--------------|---------|
| name | ✓ | string | ^[a-z][a-z0-9-]*$ | - |
| description | ✓ | string | 50-300 chars | - |
| tools | ✗ | string | comma-separated tools | all tools |
| model | ✗ | enum | sonnet\|opus\|haiku\|inherit | inherit |
| permissionMode | ✗ | enum | default\|acceptEdits\|bypassPermissions\|plan\|ignore | default |
| skills | ✗ | string | comma-separated names | none |
| aliases | ✗ | array | string array | none |

## Checklist

- [ ] Frontmatter delimiters present (`---` before and after)
- [ ] No content before opening delimiter
- [ ] Valid YAML syntax (proper indentation, no tabs)
- [ ] `name` field present and valid format
- [ ] `description` field present and descriptive
- [ ] `tools` in comma-separated string format (if present)
- [ ] `model` is valid enum value (if present)
- [ ] `permissionMode` is valid enum value (if present)
- [ ] All field names are lowercase
- [ ] No duplicate fields
- [ ] Consistent indentation throughout

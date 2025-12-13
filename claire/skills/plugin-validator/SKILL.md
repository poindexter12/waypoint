---
name: plugin-validator
description: Validate Claude Code plugin structure, manifests, frontmatter, and dependencies. Use when user mentions "validate plugin", "check plugin health", "plugin broken", "plugin not loading", "plugin errors", "plugin.json invalid", "agent not working", "check plugin structure", or reports plugin-related issues.
---

# Plugin Validator

## Validation Checks

### 1. Manifest Validation
- [ ] plugin.json exists at correct location
- [ ] Valid JSON syntax
- [ ] Required fields present (name, description, version)
- [ ] Semantic versioning format (X.Y.Z)
- [ ] Array fields properly formatted (agents, commands, skills)
- [ ] No duplicate entries

### 2. Structure Validation
- [ ] Referenced agents exist at specified paths
- [ ] Referenced commands exist at specified paths
- [ ] Referenced skills exist at specified paths
- [ ] File paths are relative (not absolute)
- [ ] No broken file references
- [ ] Directory structure follows conventions

### 3. Frontmatter Validation
- [ ] YAML syntax is valid
- [ ] Required fields present (name, description)
- [ ] Field values match allowed types
- [ ] Tools list is valid (if specified)
- [ ] Model value is valid (sonnet|opus|haiku|inherit)
- [ ] No conflicting or deprecated fields

### 4. Dependency Validation
- [ ] No circular dependencies between agents/skills
- [ ] Skill references resolve correctly
- [ ] Tool permissions are valid
- [ ] Cross-references between components exist
- [ ] External dependencies documented

### 5. Configuration Validation
- [ ] No conflicting settings between components
- [ ] File permissions are readable
- [ ] No duplicate agent/command names
- [ ] Version consistency across files
- [ ] Repository metadata accurate

## Process

1. **Identify plugin location**
   ```bash
   # Find plugin.json
   find . -name "plugin.json" -o -name ".claude-plugin/plugin.json"
   ```

2. **Run manifest validation**
   - Parse JSON syntax
   - Check required fields
   - Validate semver format
   - Verify array structures

3. **Validate file structure**
   - Read manifest file references
   - Check each referenced file exists
   - Verify paths are relative
   - Check directory conventions

4. **Check frontmatter**
   - For each agent/command file
   - Parse YAML frontmatter
   - Validate required fields
   - Check field value constraints

5. **Analyze dependencies**
   - Build dependency graph
   - Detect circular references
   - Validate skill references
   - Check tool usage patterns

6. **Report findings**
   - Categorize by severity (critical, warning, info)
   - Provide specific file/line references
   - Suggest fixes with examples
   - Prioritize by impact

## Validation Severity Levels

### CRITICAL (Plugin won't load)
- Invalid JSON in plugin.json
- Missing required fields (name, description, version)
- Referenced files don't exist
- Invalid YAML in frontmatter
- Circular dependencies

### WARNING (Plugin may malfunction)
- Invalid semver format
- Deprecated field usage
- Missing optional but recommended fields
- Inconsistent naming conventions
- Potential conflicts

### INFO (Best practice suggestions)
- Missing documentation
- Version mismatch across files
- Code style inconsistencies
- Missing cross-references
- Optimization opportunities

## Examples

✅ **Good trigger**: "Validate the waypoint plugin"
✅ **Good trigger**: "Check why my plugin isn't loading"
✅ **Good trigger**: "Plugin health check for claire"
✅ **Good trigger**: "My agent file has errors"

❌ **Bad trigger**: "Create a new plugin" (creation, not validation)
❌ **Bad trigger**: "Update plugin version" (modification, not validation)
❌ **Bad trigger**: "Install plugin" (installation, not validation)

## Common Issues and Fixes

### Issue: Plugin not loading
**Check:**
- plugin.json exists in correct location
- JSON syntax is valid
- Required fields present
- Version follows semver

**Fix:**
```bash
# Validate JSON syntax
python3 -m json.tool plugin.json

# Check location
test -f .claude-plugin/plugin.json || test -f plugin.json
```

### Issue: Agent not working
**Check:**
- Agent file exists at path in plugin.json
- YAML frontmatter is valid
- Required fields (name, description) present
- Tools list is valid

**Fix:**
```bash
# Check agent path
grep '"agents"' plugin.json

# Validate YAML (first 20 lines typically contain frontmatter)
head -20 agents/my-agent.md
```

### Issue: Circular dependencies
**Check:**
- Agent A references skill B
- Skill B references agent A
- Build dependency graph

**Fix:**
- Restructure to remove circular reference
- Extract shared logic to separate component
- Document dependency rationale

## Supporting Files

For detailed validation rules, see:
- [manifest.md](references/manifest.md) - plugin.json validation rules
- [frontmatter.md](references/frontmatter.md) - YAML frontmatter validation
- [structure.md](references/structure.md) - File structure conventions
- [dependencies.md](references/dependencies.md) - Dependency analysis

## Quick Reference

### Valid plugin.json structure
```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "version": "1.0.0",
  "agents": ["./agents/agent-name.md"],
  "commands": ["./commands/command-name.md"],
  "skills": ["./skills/skill-name"]
}
```

### Valid agent/command frontmatter
```yaml
---
name: component-name
description: Component description
tools: Read, Write, Bash
model: sonnet
---
```

### Validation command pattern
```bash
# Validate plugin at current directory
ls -la .claude-plugin/plugin.json plugin.json

# Check all referenced files
grep -o '"[^"]*\.md"' plugin.json | while read file; do
    test -f "${file//\"/}" && echo "✓ $file" || echo "✗ $file"
done
```

## Related

- Agent: `claire-plugin-manager` for plugin management and health checks
- Skill: `doc-validator` for documentation validation
- Commands: Claude Code plugin system documentation

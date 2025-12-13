# Dependency Validation

Rules for validating dependencies and cross-references between Claude Code plugin components.

## Dependency Types

### 1. Agent → Skill
Agents can reference skills for knowledge/templates:
```yaml
---
name: my-agent
description: Agent description
skills: skill-name, another-skill
---
```

### 2. Agent → Agent
Agents can invoke other agents (through coordination):
```markdown
For complex cases, delegate to the `specialized-agent` agent.
```

### 3. Skill → Agent
Skills can recommend specific agents:
```markdown
For strategic guidance, invoke the `consultant` agent.
```

### 4. Command → Agent
Commands can trigger agents:
```markdown
This command will invoke the `working-tree-consultant` agent.
```

### 5. Tool Dependencies
Agents and commands specify tool requirements:
```yaml
---
tools: Read, Write, Bash
---
```

## Circular Dependency Detection

### Definition
Circular dependency occurs when:
- Agent A references Skill B
- Skill B references Agent A
- Creates infinite loop potential

### Detection Strategy

1. **Build Dependency Graph**
```bash
# Extract all dependencies
for file in agents/*.md commands/*.md skills/*/SKILL.md; do
    # Extract frontmatter skills
    sed -n '/^---$/,/^---$/p' "$file" | grep "^skills:" | cut -d: -f2

    # Extract content references to agents
    grep -o "invoke.*\`[^`]*\`.*agent" "$file"
done
```

2. **Analyze Graph**
- Create adjacency list
- Run depth-first search (DFS)
- Detect back edges (indicate cycles)

3. **Report Cycles**
```
Circular dependency detected:
  working-tree-consultant (agent)
  → working-tree-guide (skill)
  → working-tree-consultant (agent)
```

### Common Circular Patterns

**Pattern 1: Agent-Skill Loop**
```
Agent: consultant.md
  skills: worktree-guide

Skill: worktree-guide/SKILL.md
  "For strategic advice, use consultant agent"
```

**Fix:** Remove circular reference, use one-way dependency:
```
Agent: consultant.md
  skills: worktree-guide

Skill: worktree-guide/SKILL.md
  "For strategic advice, see [strategic patterns](REFERENCE.md)"
```

**Pattern 2: Agent-Agent Loop**
```
Agent: coordinator.md
  "Delegate to author-agent"

Agent: author-agent.md
  "Ask coordinator for guidance"
```

**Fix:** Establish clear hierarchy (coordinator > author-agent):
```
Agent: coordinator.md
  "Delegate to author-agent"

Agent: author-agent.md
  "Cannot delegate upward, handle or ask user"
```

## Skill Reference Validation

### Valid Skill References

From agent frontmatter:
```yaml
---
skills: working-tree-guide, doc-validator
---
```

**Validation:**
- [ ] Skill name matches directory in `skills/`
- [ ] Skill directory contains `SKILL.md`
- [ ] Skill is in same plugin OR in installed plugins
- [ ] Comma-separated format (no extra spaces)

### Invalid References

```yaml
---
skills: ./skills/my-skill  # ✗ Use name, not path
skills: myskill,otherskill  # ⚠ No space after comma (optional)
skills: nonexistent-skill   # ✗ Skill doesn't exist
---
```

### Cross-Plugin Skills
Agents can reference skills from other installed plugins:
```yaml
---
skills: external-plugin-skill
---
```

**Validation:**
- Check if skill exists in current plugin
- If not, check installed plugins
- Warn if dependency on external plugin not documented

## Tool Permission Validation

### Valid Tool Specifications

```yaml
---
tools: Read, Write, Bash
---
```

**Available Tools:**
- `Read` - Read files from filesystem
- `Write` - Write new files
- `Edit` - Edit existing files
- `Bash` - Execute bash commands
- `Grep` - Search file contents
- `Glob` - Find files by pattern
- `AskUserQuestion` - Prompt user for input

### Validation Rules

1. **Tool Names Must Be Valid**
```yaml
---
tools: Read, FileRead  # ✗ FileRead is not valid
tools: Read, Write     # ✓ Both valid
---
```

2. **Minimal Tool Set Principle**
Only request tools actually needed:
```yaml
# ✗ Agent only reads files but requests all
---
tools: Read, Write, Edit, Bash
---

# ✓ Agent only requests what it needs
---
tools: Read
---
```

3. **Tool Usage Must Match Declaration**
If agent uses `Write`, it must be in tools list:
```yaml
---
tools: Read  # ✗ Missing Write
---

# Later in agent:
"Write the file to disk..."  # Uses Write but not declared
```

### Tool Usage Analysis

**Scan agent/command content for tool usage:**
```bash
# Check for Write usage
grep -i "write.*file\|create.*file" agent.md

# Check for Bash usage
grep -i "bash\|execute.*command\|run.*command" agent.md

# Check for Edit usage
grep -i "edit.*file\|modify.*file\|update.*file" agent.md
```

**Compare with declared tools:**
```bash
# Extract declared tools
DECLARED=$(sed -n '/^---$/,/^---$/p' agent.md | grep "^tools:" | cut -d: -f2)

# Check if Write is declared but used
grep -qi "write.*file" agent.md && echo "$DECLARED" | grep -q "Write" || echo "⚠ Write used but not declared"
```

## Dependency Graph Visualization

### Simple Text Format
```
plugin-name dependencies:

Agents:
  consultant
    → skills: worktree-guide
    → tools: Read, Bash

  author-agent
    → skills: doc-validator
    → tools: Read, Write, Edit
    → references: coordinator (soft)

Skills:
  worktree-guide
    → references: consultant (soft)

  doc-validator
    (no dependencies)

Commands:
  new
    → tools: Read, Write, Bash
    → triggers: consultant (conditional)
```

### Cycle Detection Output
```
✓ No circular dependencies detected

Dependency chain analysis:
  consultant → worktree-guide (OK)
  author-agent → doc-validator (OK)
  coordinator → author-agent (OK)
  coordinator → author-command (OK)

Hard dependencies: 4
Soft references: 2
```

## Validation Commands

### Build Dependency List
```bash
#!/bin/bash
# Extract all skill dependencies from agents

echo "Agent Skill Dependencies:"
echo "========================="

for agent in agents/*.md; do
    AGENT_NAME=$(basename "$agent" .md)
    SKILLS=$(sed -n '/^---$/,/^---$/p' "$agent" | grep "^skills:" | cut -d: -f2)

    if [ -n "$SKILLS" ]; then
        echo "$AGENT_NAME:"
        echo "$SKILLS" | tr ',' '\n' | sed 's/^/  → /'
    fi
done
```

### Check Skill References Exist
```bash
#!/bin/bash
# Validate all skill references exist

ERRORS=0

for file in agents/*.md commands/*.md; do
    # Extract skill references
    SKILLS=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^skills:" | cut -d: -f2)

    if [ -z "$SKILLS" ]; then
        continue
    fi

    # Check each skill exists
    echo "$SKILLS" | tr ',' '\n' | while read skill; do
        skill=$(echo "$skill" | xargs)  # Trim whitespace

        if [ -d "skills/$skill" ] && [ -f "skills/$skill/SKILL.md" ]; then
            echo "✓ $file → $skill"
        else
            echo "✗ $file → $skill (NOT FOUND)"
            ((ERRORS++))
        fi
    done
done

exit $ERRORS
```

### Detect Circular References
```bash
#!/bin/bash
# Simple circular dependency detection

echo "Checking for circular dependencies..."

# Build dependency map
declare -A deps

# Extract agent → skill dependencies
for agent in agents/*.md; do
    AGENT_NAME=$(basename "$agent" .md)
    SKILLS=$(sed -n '/^---$/,/^---$/p' "$agent" | grep "^skills:" | cut -d: -f2)

    if [ -n "$SKILLS" ]; then
        deps["agent:$AGENT_NAME"]="$SKILLS"
    fi
done

# Extract skill → agent references
for skill in skills/*/SKILL.md; do
    SKILL_NAME=$(basename "$(dirname "$skill")")
    AGENTS=$(grep -o 'invoke.*`[^`]*`.*agent' "$skill" | grep -o '`[^`]*`' | tr -d '`')

    if [ -n "$AGENTS" ]; then
        deps["skill:$SKILL_NAME"]="$AGENTS"
    fi
done

# Check for cycles (simplified - checks one level)
for key in "${!deps[@]}"; do
    echo "$key → ${deps[$key]}"

    # Check if any dependency points back
    # (Real implementation would use proper graph traversal)
done
```

## Common Issues

### Issue: Missing Skill Reference
```yaml
---
skills: nonexistent-skill
---
```
**Detection:** Skill directory doesn't exist
**Fix:** Create skill or remove reference

### Issue: Typo in Skill Name
```yaml
---
skills: working-tree-guid  # Missing 'e'
---
```
**Detection:** Similar name exists
**Fix:** Correct spelling

### Issue: External Skill Not Available
```yaml
---
skills: external-plugin-skill
---
```
**Detection:** Skill not in current plugin, external plugin not installed
**Fix:** Document dependency or include skill

### Issue: Tool Not Declared
Agent uses Write but doesn't declare it:
```yaml
---
tools: Read  # Missing Write
---
```
**Detection:** Content analysis shows Write usage
**Fix:** Add Write to tools list

### Issue: Unnecessary Tools
```yaml
---
tools: Read, Write, Edit, Bash, Grep, Glob  # ✗ Too many
---

# Agent only reads files
```
**Detection:** Content analysis shows only Read usage
**Fix:** Remove unused tools

## Validation Checklist

### Skill References
- [ ] All referenced skills exist in current plugin
- [ ] OR referenced skills exist in installed plugins
- [ ] Skill names spelled correctly
- [ ] Comma-separated format correct
- [ ] No circular agent → skill → agent references

### Tool Permissions
- [ ] All tool names are valid
- [ ] Tools list matches actual usage
- [ ] Minimal tool set requested
- [ ] No unnecessary tools declared

### Cross-References
- [ ] Agent-to-agent references are one-way
- [ ] Skill recommendations are documented
- [ ] Command-to-agent triggers are valid
- [ ] No circular dependencies

### Dependency Documentation
- [ ] External dependencies documented
- [ ] Plugin dependencies clear
- [ ] Version requirements specified (if any)
- [ ] Optional vs required dependencies marked

## Dependency Best Practices

1. **Prefer One-Way Dependencies**
   - Establish clear hierarchy
   - Avoid circular references
   - Document dependency rationale

2. **Minimize Tool Permissions**
   - Request only needed tools
   - Start with minimal set
   - Add tools only when required

3. **Document External Dependencies**
   - List required plugins
   - Specify version requirements
   - Provide installation instructions

4. **Keep Dependency Graph Shallow**
   - Limit dependency depth
   - Avoid long chains
   - Consider extracting shared logic

5. **Validate Before Committing**
   - Run dependency checks
   - Test with clean plugin installation
   - Verify external dependencies available

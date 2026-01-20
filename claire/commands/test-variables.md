---
description: Test dynamic variable injection ($ARGUMENTS, $TOOL_INPUT, $TOOL_OUTPUT)
argument-hint: [test-name]
allowed-tools: Bash, Read, Write
model: haiku
---

# /test-variables

Test and document Claude Code dynamic variable injection behavior. This command investigates documented (but possibly undocumented in examples) variables like $ARGUMENTS, $SELECTION, $TOOL_INPUT, and $TOOL_OUTPUT.

## ARGUMENT SPECIFICATION

```
SYNTAX: /test-variables [test-name]

OPTIONAL:
  [test-name]
    Type: enum[arguments, tool-input, tool-output, all]
    Default: all
    Purpose: Run specific test or all tests
```

## PURPOSE

Official Claude Code documentation mentions these dynamic variables:
- `$ARGUMENTS` - Command/skill arguments passed by user
- `$SELECTION` - Editor selection (IDE integration context)
- `$TOOL_INPUT` - Available in PreToolUse hooks
- `$TOOL_OUTPUT` - Available in PostToolUse hooks

However, official example skills don't use these variables, preferring explicit file loading instructions instead. This command tests whether these variables work as documented and documents findings for plugin authors.

## EXECUTION PROTOCOL

### STEP 1: PARSE ARGUMENTS

Determine which test to run:
- `arguments` → Test $ARGUMENTS variable only
- `tool-input` → Test $TOOL_INPUT in hooks only
- `tool-output` → Test $TOOL_OUTPUT in hooks only
- `all` (default) → Run all tests

### STEP 2: TEST $ARGUMENTS

**Test Procedure:**
1. This command was invoked with arguments: `$ARGUMENTS`
2. Report what the $ARGUMENTS variable contains
3. Document format, structure, and accessibility

**Expected Outcomes:**
- If `$ARGUMENTS` resolves → Variable works, document format
- If `$ARGUMENTS` is literal string → Variable not interpolated at this level
- If empty → Variable may not be set in this context

**Report:**
```
## $ARGUMENTS Test Result

Invoked as: /test-variables {provided_args}
$ARGUMENTS value: {value or "not resolved"}

Interpretation:
- {explanation of what this means for plugin authors}
```

### STEP 3: TEST $TOOL_INPUT / $TOOL_OUTPUT

These variables are documented for hooks, not skills/commands. Document this limitation.

**Report:**
```
## Hook Variables ($TOOL_INPUT, $TOOL_OUTPUT)

These variables are documented for PreToolUse and PostToolUse hooks,
not for skills or commands.

To test these, you would need to:
1. Create a hook configuration in CLAUDE.md
2. Run a tool that triggers the hook
3. Observe the hook output

Example hook testing approach:
[provide example if hooks are configured]
```

### STEP 4: TEST $SELECTION

Selection context is IDE-specific (Cursor, VS Code extension, etc.).

**Report:**
```
## $SELECTION Test Result

$SELECTION value: {value or "not available in CLI context"}

Note: $SELECTION requires IDE integration and an active text selection.
This variable is not available in pure CLI contexts.
```

### STEP 5: DOCUMENT FINDINGS

Write findings to `claire/docs-cache/dynamic-variables.md`:

```markdown
# Dynamic Variables Investigation

Tested: {timestamp}
Context: Claude Code CLI

## Summary

| Variable | Documented | Works | Context |
|----------|-----------|-------|---------|
| $ARGUMENTS | Yes | {result} | Skills/Commands |
| $SELECTION | Yes | {result} | IDE only |
| $TOOL_INPUT | Yes | {result} | Hooks only |
| $TOOL_OUTPUT | Yes | {result} | Hooks only |

## Detailed Findings

[Results from each test]

## Recommendations for Plugin Authors

[Based on findings]
```

### STEP 6: OUTPUT SUMMARY

```
Variable Testing Complete

Results:
- $ARGUMENTS: {status}
- $SELECTION: {status}
- $TOOL_INPUT: {status}
- $TOOL_OUTPUT: {status}

Full report written to: claire/docs-cache/dynamic-variables.md
```

## IMPORTANT NOTES

1. **This is exploratory research** - Official examples don't use these variables
2. **Context matters** - Variables may work differently in:
   - Skills vs Commands
   - CLI vs IDE
   - Hooks vs direct invocation
3. **Document findings** - Update claire/docs-cache/dynamic-variables.md with results

## ALTERNATIVE PATTERNS

If dynamic variables don't work as expected, use these patterns instead:

**For Arguments:**
```markdown
Parse the user's command invocation to extract arguments.
The invocation format is: /command-name [args]
```

**For File Content:**
```markdown
Read [filename] to get the content needed for this operation.
```

**For Tool Context in Hooks:**
```yaml
# hooks section in CLAUDE.md
hooks:
  PostToolUse:
    - matcher:
        tool_name: "Write"
      action:
        type: command
        command: "echo 'File written'"
```

## VERSION

- Version: 1.0.0
- Created: 2026-01-20
- Purpose: Research dynamic variable injection for plugin development

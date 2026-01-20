---
description: Test dynamic variable injection ($ARGUMENTS, $SELECTION)
argument-hint: <any-args-here>
allowed-tools: Bash, Read
model: haiku
---

# /claire:test-variables

Test whether Claude Code dynamic variables get interpolated.

## Arguments Received

The arguments passed to this command are: $ARGUMENTS

## Selection Content

The current editor selection is: $SELECTION

## Your Task

Report what you see above:

1. **$ARGUMENTS test**: Look at "Arguments Received" section above.
   - If you see actual argument text → variable works
   - If you see literal "$ARGUMENTS" → variable not interpolated
   - If empty → variable set but empty

2. **$SELECTION test**: Look at "Selection Content" section above.
   - If you see text content → variable works (IDE context)
   - If you see literal "$SELECTION" → variable not interpolated
   - If empty → likely CLI context (no selection available)

3. **Report findings** - Tell the user what worked and what didn't.

## Version

- Version: 2.0.0
- Updated: 2026-01-20
- Purpose: Empirically test dynamic variable injection

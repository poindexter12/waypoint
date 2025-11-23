---
name: doc-validator
description: Validate documentation files for completeness, accuracy, and consistency. Use when checking README files, API docs, or documentation quality.
allowed-tools: Read, Grep, Glob
---

# Documentation Validator Skill

Validates documentation files to ensure they are complete, accurate, and consistent with the codebase.

## When to Use

Activate this skill when:
- User mentions "check documentation" or "validate docs"
- User asks "is the README up to date?"
- User requests documentation review
- User mentions "docs are wrong" or "fix the docs"
- Working on documentation improvements

## Validation Checks

### 1. Completeness
- [ ] Installation instructions present
- [ ] Usage examples provided
- [ ] API reference complete (if applicable)
- [ ] Troubleshooting section exists
- [ ] Contributing guidelines (if open source)

### 2. Accuracy
- [ ] Code examples are runnable
- [ ] Commands match actual CLI
- [ ] File paths exist
- [ ] Version numbers match package.json/pyproject.toml
- [ ] Links are not broken

### 3. Consistency
- [ ] Terminology is consistent
- [ ] Code style in examples matches project
- [ ] Formatting is uniform
- [ ] Table of contents matches headings

### 4. Quality
- [ ] No spelling/grammar errors
- [ ] Clear and concise language
- [ ] Proper markdown formatting
- [ ] Code blocks have language hints

## Process

1. **Find documentation files**
   ```bash
   find . -name "*.md" -o -name "*.rst"
   ```

2. **Read and analyze**
   - Check structure (headings, sections)
   - Verify code examples
   - Validate links and references

3. **Cross-reference with code**
   - Compare CLI commands with actual implementation
   - Verify file paths exist
   - Check version numbers

4. **Report findings**
   - List issues by category
   - Suggest improvements
   - Provide examples of fixes

## Examples

✅ **Good trigger**: "Check if our README is complete"
✅ **Good trigger**: "Validate the API documentation"
✅ **Good trigger**: "The docs mention /old-command but I don't see it in the code"

❌ **Bad trigger**: "Write new documentation" (creation, not validation)
❌ **Bad trigger**: "Fix typo in line 42" (too specific, not validation)

## Supporting Files

For detailed validation rules, see [REFERENCE.md](REFERENCE.md).

For common issues and fixes, see the `/templates` directory.

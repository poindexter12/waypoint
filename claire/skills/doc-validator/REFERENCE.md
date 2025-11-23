# Documentation Validator Reference

Detailed validation rules and patterns for documentation quality assurance.

## Markdown Linting Rules

### Headings
- Must start with `#` (H1) for document title
- No skipping heading levels (no H1 → H3)
- Each heading should be unique
- Use sentence case for headings

### Code Blocks
- Always specify language: ` ```bash `, ` ```python `, etc.
- Code should be runnable (or marked as pseudocode)
- Avoid long lines (max 80-100 characters)

### Links
- Use relative links for internal files
- Check external links are accessible
- Use descriptive link text (not "click here")

### Lists
- Consistent marker style (- vs * vs +)
- Proper indentation for nested lists
- Complete sentences with periods

## Version Validation

Check version consistency across:
- package.json (`version` field)
- pyproject.toml (`version` field)
- README.md (version badges, installation commands)
- CHANGELOG.md (latest version entry)
- setup.py (`version` field)

## CLI Command Validation

For each command mentioned in docs:
1. Search for actual implementation
2. Verify flags/arguments match
3. Check help text matches documentation
4. Validate examples are correct

Example check:
```bash
# Documentation says:
make install MODULE=foo

# Verify:
grep -r "CLAUDE_DIR" Makefile  # Check parameter exists
make help                       # Verify command listed
```

## Common Issues

### Missing Installation Steps
- No prerequisites listed
- No dependency installation
- Missing system requirements
- No version requirements

### Broken Examples
- Code examples with syntax errors
- Commands that don't exist
- File paths that don't exist
- Outdated package names

### Inconsistent Terminology
- "repo" vs "repository"
- "module" vs "package"
- "CLI" vs "command-line tool"

Pick one term and use it throughout.

## Auto-Fix Patterns

Some issues can be auto-fixed:
- Add missing code block language hints
- Fix heading hierarchy
- Normalize list markers
- Add table of contents
- Update version numbers

Ask user before applying fixes.

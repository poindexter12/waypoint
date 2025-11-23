---
description: Fetch latest Claude Code documentation for agents, commands, and skills
argument-hint: [--force] [--doc-name]
allowed-tools: Read, Write, WebFetch, Bash
---

## /claire-fetch-docs

Fetches the latest Claude Code documentation from the official docs site and caches it locally for use by the claire agent.

**Purpose**: Ensure claire always has up-to-date documentation when creating or optimizing agents, commands, and skills.

### Usage

```
/claire-fetch-docs              # Fetch all docs (respects cache)
/claire-fetch-docs --force      # Force refresh all docs
/claire-fetch-docs skills       # Fetch only skills documentation
```

### Process

1. **Read docs-index.json**
   - Location: `claire/docs-index.json`
   - Contains URLs for all key documentation

2. **Check cache**
   - Cache directory: `claire/docs-cache/`
   - Cache lifetime: 24 hours (86400 seconds)
   - Skip if cached and fresh (unless `--force`)

3. **Fetch documentation**
   - Use WebFetch to retrieve markdown from code.claude.com
   - Prompt: "Return the full documentation content"
   - Save to cache with timestamp

4. **Update index**
   - Update `lastFetched` timestamp in docs-index.json
   - Report what was fetched

### Cache Structure

```
claire/docs-cache/
├── skills.md
├── plugins.md
├── hooks-guide.md
├── sub-agents.md
├── slash-commands.md
├── .metadata.json  # Timestamps and URLs
└── README.md       # Cache info
```

### Examples

**Fetch all documentation:**
```
/claire-fetch-docs
```

**Output:**
```
Fetching Claude Code documentation...

✓ skills (cached, fresh)
✓ plugins (cached, fresh)
→ Fetching sub-agents (cache expired)
→ Fetching slash-commands (cache expired)

Fetched 2 docs, 2 cached
Documentation ready for claire agent
```

**Force refresh everything:**
```
/claire-fetch-docs --force
```

**Fetch specific doc:**
```
/claire-fetch-docs skills
```

### Implementation Notes

- Create `claire/docs-cache/` if it doesn't exist
- Create `.metadata.json` to track fetch times:
  ```json
  {
    "skills": {
      "url": "https://code.claude.com/docs/en/skills.md",
      "lastFetched": "2025-11-23T12:34:56Z",
      "size": 12345
    }
  }
  ```
- Use WebFetch with prompt: "Return the full documentation content as markdown"
- Handle fetch errors gracefully (report but continue)
- Skip docs that are fresh (< 24 hours old) unless `--force`
- Update docs-index.json with lastFetched timestamps

### Error Handling

- **Network error**: Report and continue with cached docs
- **Invalid URL**: Skip and report
- **Cache directory missing**: Create it
- **Permission denied**: Report clearly

### Integration with Claire Agent

The claire agent should:
1. Run `/claire-fetch-docs` at startup (respects cache)
2. Read cached docs from `claire/docs-cache/`
3. Reference latest docs when creating/optimizing agents/commands/skills
4. Suggest running `/claire-fetch-docs --force` if user reports outdated info

---
description: Fetch latest Claude Code documentation for agents, commands, and skills
argument-hint: [--force] [--doc-name]
allowed-tools: Read, Write, WebFetch, Bash
model: sonnet
---

# /fetch:docs-claire

Fetch latest Claude Code documentation from official docs site and cache locally for claire agents.

## ARGUMENT SPECIFICATION

```
SYNTAX: /fetch:docs-claire [--force] [doc-name]

OPTIONAL:
  --force
    Type: flag
    Default: false
    Purpose: Force refresh even if cache is fresh

  [doc-name]
    Type: enum[skills, plugins, hooks-guide, sub-agents, slash-commands]
    Default: (all docs)
    Purpose: Fetch specific doc only
```

## EXECUTION PROTOCOL

Execute steps sequentially. Each step must complete successfully before proceeding.

### STEP 1: PARSE ARGUMENTS

PARSE:
```bash
FORCE_REFRESH=false
TARGET_DOC="all"

for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        FORCE_REFRESH=true
    elif [ "$arg" != "--force" ]; then
        TARGET_DOC="$arg"
    fi
done
```

VALIDATION:
- IF TARGET_DOC not in [all, skills, plugins, hooks-guide, sub-agents, slash-commands] → ERROR PATTERN "invalid-doc-name"

NEXT:
- On success → STEP 2
- On failure → ABORT

### STEP 2: ENSURE CACHE DIRECTORY EXISTS

EXECUTE:
```bash
CACHE_DIR="claire/docs-cache"
test -d "$CACHE_DIR"
DIR_EXISTS=$?

if [ $DIR_EXISTS -ne 0 ]; then
    mkdir -p "$CACHE_DIR"
    MKDIR_EXIT=$?
fi
```

VALIDATION:
- IF mkdir fails → ERROR PATTERN "cache-dir-creation-failed"

DATA:
- CACHE_DIR = "claire/docs-cache"

NEXT:
- On success → STEP 3
- On failure → ABORT

### STEP 3: READ DOCS INDEX

EXECUTE:
```bash
INDEX_FILE="claire/docs-index.json"
test -f "$INDEX_FILE"
INDEX_EXISTS=$?

if [ $INDEX_EXISTS -eq 0 ]; then
    INDEX_JSON=$(cat "$INDEX_FILE" 2>&1)
    CAT_EXIT=$?
else
    INDEX_JSON="{}"
    CAT_EXIT=0
fi
```

VALIDATION:
- IF INDEX_EXISTS == 0 AND CAT_EXIT != 0 → ERROR PATTERN "index-read-failed"

PARSE INDEX:
```json
{
  "skills": {
    "url": "https://code.claude.com/docs/en/skills",
    "lastFetched": "2025-11-23T12:34:56Z"
  },
  "sub-agents": {
    "url": "https://code.claude.com/docs/en/sub-agents",
    "lastFetched": "2025-11-23T10:00:00Z"
  },
  ...
}
```

DOC LIST:
- skills
- plugins
- hooks-guide
- sub-agents
- slash-commands

NEXT:
- On success → STEP 4
- On failure with empty JSON → STEP 4 (will fetch all)

### STEP 4: DETERMINE WHICH DOCS TO FETCH

ALGORITHM:
```python
docs_to_fetch = []

if TARGET_DOC == "all":
    check_all_docs = ["skills", "plugins", "hooks-guide", "sub-agents", "slash-commands"]
else:
    check_all_docs = [TARGET_DOC]

for doc_name in check_all_docs:
    cache_file = f"{CACHE_DIR}/{doc_name}.md"

    if FORCE_REFRESH:
        docs_to_fetch.append(doc_name)
        status[doc_name] = "force refresh"
    elif not file_exists(cache_file):
        docs_to_fetch.append(doc_name)
        status[doc_name] = "not cached"
    else:
        file_age = current_time - file_mtime(cache_file)
        if file_age > 86400:  # 24 hours in seconds
            docs_to_fetch.append(doc_name)
            status[doc_name] = "cache expired"
        else:
            status[doc_name] = "cached, fresh"
```

CACHE LIFETIME: 24 hours (86400 seconds)

OUTPUT:
- docs_to_fetch = list of doc names that need fetching
- status = dict of doc_name → status string

NEXT:
- IF docs_to_fetch is empty → STEP 7 (all fresh, skip fetching)
- IF docs_to_fetch not empty → STEP 5

### STEP 5: FETCH DOCUMENTATION

FOR EACH doc_name in docs_to_fetch:

```bash
URL=$(jq -r ".\"$doc_name\".url" "$INDEX_FILE" 2>/dev/null)
if [ -z "$URL" ] || [ "$URL" = "null" ]; then
    # Construct default URL
    URL="https://code.claude.com/docs/en/${doc_name}"
fi

# Fetch using WebFetch
WebFetch(
    url="$URL",
    prompt="Return the full documentation content as markdown. Include all sections, examples, and code blocks."
)

FETCH_EXIT=$?
```

VALIDATION:
- IF FETCH_EXIT != 0 → ERROR PATTERN "fetch-failed" (non-fatal, continue with others)
- IF content is empty → ERROR PATTERN "empty-response" (non-fatal)

SAVE TO CACHE:
```bash
if [ $FETCH_EXIT -eq 0 ] && [ -n "$CONTENT" ]; then
    echo "$CONTENT" > "$CACHE_DIR/${doc_name}.md"
    WRITE_EXIT=$?

    if [ $WRITE_EXIT -eq 0 ]; then
        fetched_count=$((fetched_count + 1))
        status[doc_name]="✓ fetched"
    else
        status[doc_name]="✗ write failed"
    fi
else
    status[doc_name]="✗ fetch failed"
fi
```

NEXT:
- Continue with next doc in list
- After all processed → STEP 6

### STEP 6: UPDATE METADATA

EXECUTE:
```bash
METADATA_FILE="$CACHE_DIR/.metadata.json"
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update metadata for each successfully fetched doc
for doc_name in successfully_fetched:
    jq ".\"$doc_name\".lastFetched = \"$CURRENT_TIME\"" "$METADATA_FILE" > tmp.json
    mv tmp.json "$METADATA_FILE"
done
```

CREATE/UPDATE INDEX:
```json
{
  "doc-name": {
    "url": "https://...",
    "lastFetched": "2025-11-24T12:00:00Z",
    "size": 12345
  }
}
```

NEXT:
- On success → STEP 7
- On failure → Warn (not critical)

### STEP 7: OUTPUT SUMMARY

OUTPUT FORMAT (exact):
```
{IF any fetched}
Fetching Claude Code documentation...

{FOR EACH doc in check_all_docs}
{STATUS_INDICATOR} {doc_name} ({status_message})
{END FOR}

{SUMMARY_LINE}

{ELSE}
All documentation is fresh (< 24h old)

Use --force to refresh anyway.
{END IF}
```

STATUS INDICATORS:
- ✓ = successfully fetched or cached fresh
- → = fetching now
- ✗ = fetch failed

SUMMARY LINE:
```
Fetched {N} docs, {M} cached, {K} failed
Documentation ready for claire agents
```

SPECIAL CASES:
- IF all cached, fresh: "All documentation is fresh (< 24h old)"
- IF all failed: "Failed to fetch any documentation. Using cached versions."
- IF TARGET_DOC specified: "Fetched {doc-name} documentation"

NEXT:
- TERMINATE (success)

## ERROR PATTERNS

### PATTERN: invalid-doc-name

DETECTION:
- TRIGGER: TARGET_DOC not in valid doc list
- CHECK: doc_name not in [skills, plugins, hooks-guide, sub-agents, slash-commands]

RESPONSE (exact):
```
Error: Invalid documentation name '{DOC_NAME}'

Valid documentation names:
  - skills
  - plugins
  - hooks-guide
  - sub-agents
  - slash-commands

Usage:
  /fetch:docs-claire                # Fetch all docs
  /fetch:docs-claire skills         # Fetch specific doc
  /fetch:docs-claire --force        # Force refresh all
```

TEMPLATE SUBSTITUTIONS:
- {DOC_NAME} = invalid doc name provided

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: cache-dir-creation-failed

DETECTION:
- TRIGGER: mkdir fails for cache directory
- CAPTURE: mkdir error message

RESPONSE (exact):
```
Error: Failed to create cache directory

Directory: {CACHE_DIR}
Error: {MKDIR_ERROR}

Check:
- Write permissions on claire/ directory
- Disk space available
- Path is valid
```

TEMPLATE SUBSTITUTIONS:
- {CACHE_DIR} = claire/docs-cache
- {MKDIR_ERROR} = captured error

CONTROL FLOW:
- ABORT: true
- CLEANUP: none
- RETRY: false

### PATTERN: index-read-failed

DETECTION:
- TRIGGER: docs-index.json exists but cannot be read
- CHECK: file exists but cat fails

RESPONSE (exact):
```
Warning: Could not read docs-index.json

Proceeding with default documentation URLs.

If this persists, check file permissions on:
  claire/docs-index.json
```

CONTROL FLOW:
- ABORT: false (warning, use defaults)
- CLEANUP: none
- FALLBACK: Use hardcoded default URLs

### PATTERN: fetch-failed

DETECTION:
- TRIGGER: WebFetch fails for a specific doc
- CAPTURE: fetch error or network issue
- OCCURS: per-doc, not fatal to entire operation

RESPONSE:
```
✗ {DOC_NAME} (fetch failed: {ERROR_MESSAGE})
```

TEMPLATE SUBSTITUTIONS:
- {DOC_NAME} = doc that failed to fetch
- {ERROR_MESSAGE} = brief error description

CONTROL FLOW:
- ABORT: false (continue with other docs)
- CLEANUP: none
- FALLBACK: Use cached version if available

### PATTERN: empty-response

DETECTION:
- TRIGGER: WebFetch succeeds but returns empty content
- CHECK: content length == 0 or content is whitespace only

RESPONSE:
```
✗ {DOC_NAME} (empty response from server)
```

CONTROL FLOW:
- ABORT: false (continue with other docs)
- CLEANUP: Don't overwrite existing cache
- FALLBACK: Keep existing cached version

## TOOL PERMISSION MATRIX

| Tool | Pattern | Permission | Pre-Check | Post-Check | On-Deny-Action |
|------|---------|------------|-----------|------------|----------------|
| Read | claire/docs-index.json | ALLOW | N/A | N/A | N/A |
| Read | claire/docs-cache/*.md | ALLOW | N/A | N/A | N/A |
| Write | claire/docs-cache/*.md | ALLOW | dir_exists | file_created | N/A |
| Write | claire/docs-cache/.metadata.json | ALLOW | dir_exists | valid_json | N/A |
| WebFetch | code.claude.com/* | ALLOW | url_valid | content_received | N/A |
| Bash | mkdir claire/docs-cache | ALLOW | N/A | dir_created | N/A |
| Bash | test:* | ALLOW | N/A | N/A | N/A |
| Bash | cat:* | ALLOW | N/A | N/A | N/A |
| Bash | date:* | ALLOW | N/A | N/A | N/A |
| Bash | jq:* | ALLOW | N/A | N/A | N/A |
| Bash | mv:* | ALLOW | N/A | N/A | N/A |
| Bash | rm claire/docs-cache/* | DENY | N/A | N/A | ABORT "Use --force to refresh" |
| Bash | sudo:* | DENY | N/A | N/A | ABORT "Elevated privileges" |
| Write | **/.env* | DENY | N/A | N/A | ABORT "Secrets file" |

SECURITY CONSTRAINTS:
- Can ONLY fetch from code.claude.com domain
- Can ONLY write to claire/docs-cache/ directory
- CANNOT delete cache files (only overwrite)
- CANNOT execute arbitrary web requests
- All fetched content must be documentation

## TEST CASES

### TC001: Fetch all docs with fresh cache

PRECONDITIONS:
- Cache directory exists: claire/docs-cache/
- All docs cached and fresh (< 24h old)
- No --force flag

INPUT:
```
/fetch:docs-claire
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → FORCE_REFRESH=false, TARGET_DOC="all"
2. STEP 2 → Cache dir exists
3. STEP 3 → Read index successfully
4. STEP 4 → All docs have status "cached, fresh", docs_to_fetch = []
5. STEP 7 → Output "All fresh" message
6. TERMINATE

EXPECTED OUTPUT:
```
All documentation is fresh (< 24h old)

Use --force to refresh anyway.
```

VALIDATION:
```bash
# Verify no files were modified
find claire/docs-cache -name "*.md" -mmin -1 | wc -l  # Should be 0
```

### TC002: Fetch all with expired cache

PRECONDITIONS:
- Cache directory exists
- Some docs cached but > 24h old
- Some docs not cached

INPUT:
```
/fetch:docs-claire
```

EXPECTED EXECUTION FLOW:
1-4. Standard flow, identify expired/missing docs
5. STEP 5 → Fetch expired and missing docs via WebFetch
6. STEP 6 → Update metadata with new timestamps
7. STEP 7 → Output summary with fetch results

EXPECTED OUTPUT:
```
Fetching Claude Code documentation...

✓ skills (cached, fresh)
→ Fetching plugins (cache expired)
→ Fetching sub-agents (not cached)
✓ hooks-guide (cached, fresh)
✓ slash-commands (cached, fresh)

Fetched 2 docs, 3 cached
Documentation ready for claire agents
```

VALIDATION:
```bash
# Verify docs were updated
test -f claire/docs-cache/plugins.md && echo "PASS" || echo "FAIL"
test -f claire/docs-cache/sub-agents.md && echo "PASS" || echo "FAIL"
find claire/docs-cache -name "plugins.md" -mmin -1 | grep -q plugins && echo "PASS" || echo "FAIL"
```

### TC003: Force refresh all

PRECONDITIONS:
- Cache exists with fresh docs

INPUT:
```
/fetch:docs-claire --force
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → FORCE_REFRESH=true, TARGET_DOC="all"
2-4. All docs added to docs_to_fetch regardless of age
5. STEP 5 → Fetch all docs
6-7. Update and output

EXPECTED OUTPUT:
```
Fetching Claude Code documentation...

→ Fetching skills (force refresh)
→ Fetching plugins (force refresh)
→ Fetching hooks-guide (force refresh)
→ Fetching sub-agents (force refresh)
→ Fetching slash-commands (force refresh)

Fetched 5 docs, 0 cached
Documentation ready for claire agents
```

VALIDATION:
```bash
# Verify all files were updated recently
find claire/docs-cache -name "*.md" -mmin -1 | wc -l  # Should be 5
```

### TC004: Fetch specific doc

PRECONDITIONS:
- Cache directory exists

INPUT:
```
/fetch:docs-claire skills
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → TARGET_DOC="skills"
2-4. Only check skills doc
5. STEP 5 → Fetch only skills
6-7. Update and output

EXPECTED OUTPUT:
```
Fetching Claude Code documentation...

→ Fetching skills (cache expired)

Fetched skills documentation
Documentation ready for claire agents
```

VALIDATION:
```bash
test -f claire/docs-cache/skills.md && echo "PASS" || echo "FAIL"
```

### TC005: Network failure (partial)

PRECONDITIONS:
- Need to fetch 3 docs
- Network fails for 1 doc

INPUT:
```
/fetch:docs-claire --force
```

EXPECTED EXECUTION FLOW:
1-4. Standard flow
5. STEP 5 → Fetch each doc, one fails with network error
6. ERROR PATTERN "fetch-failed" for failed doc (non-fatal)
7. Continue with remaining docs
8. STEP 7 → Output summary showing failure

EXPECTED OUTPUT:
```
Fetching Claude Code documentation...

✓ skills (force refresh)
✗ plugins (fetch failed: network timeout)
✓ hooks-guide (force refresh)
✓ sub-agents (force refresh)
✓ slash-commands (force refresh)

Fetched 4 docs, 0 cached, 1 failed
Some documentation may be outdated. Using cached versions where available.
```

### TC006: Cache directory doesn't exist

PRECONDITIONS:
- claire/docs-cache/ does not exist

INPUT:
```
/fetch:docs-claire
```

EXPECTED EXECUTION FLOW:
1. STEP 1 → Parse args
2. STEP 2 → DIR_EXISTS != 0, create directory
3-7. Standard flow with newly created directory

EXPECTED OUTPUT:
```
Created cache directory: claire/docs-cache

Fetching Claude Code documentation...

→ Fetching skills (not cached)
→ Fetching plugins (not cached)
...

Fetched 5 docs, 0 cached
Documentation ready for claire agents
```

VALIDATION:
```bash
test -d claire/docs-cache && echo "PASS" || echo "FAIL"
test -f claire/docs-cache/.metadata.json && echo "PASS" || echo "FAIL"
```

## CACHE STRUCTURE

```
claire/
├── docs-index.json          # URL mappings and config
└── docs-cache/
    ├── skills.md
    ├── plugins.md
    ├── hooks-guide.md
    ├── sub-agents.md
    ├── slash-commands.md
    └── .metadata.json       # Fetch timestamps and metadata
```

### .metadata.json FORMAT

```json
{
  "skills": {
    "url": "https://code.claude.com/docs/en/skills",
    "lastFetched": "2025-11-24T12:00:00Z",
    "size": 12345,
    "status": "success"
  },
  "sub-agents": {
    "url": "https://code.claude.com/docs/en/sub-agents",
    "lastFetched": "2025-11-24T12:00:05Z",
    "size": 23456,
    "status": "success"
  }
}
```

## INTEGRATION NOTES

### With Claire Agents

Claire agents (author-agent, author-command) should:
1. Check if docs-cache exists and is fresh
2. If missing or stale (> 24h), recommend running /fetch:docs-claire
3. Read cached docs from claire/docs-cache/ for specifications
4. Reference latest patterns and examples from cached docs

### Cache Lifetime

- Default: 24 hours (86400 seconds)
- Rationale: Documentation doesn't change frequently, reduce network load
- Override: Use --force to refresh regardless of age

## RELATED COMMANDS

- None (standalone command for documentation management)

## DELEGATION

Not applicable - this is a simple fetch-and-cache operation with no complex decision-making requiring agent delegation.

## VERSION

- Version: 2.0.0
- Created: 2025-11-23
- Updated: 2025-11-24 (AI optimization, renamed to /fetch:docs-claire)
- Purpose: Fetch and cache Claude Code documentation for claire agents
- Changelog:
  - 2.0.0 (2025-11-24): AI-optimized with execution protocol, error patterns
  - 1.0.0 (2025-11-23): Initial creation

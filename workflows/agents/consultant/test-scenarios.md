# Test Scenarios Reference

Test scenarios for validating the Working Tree Consultant agent behavior. Use these to verify correct invocation, flow, and output.

## TS001: Migration consultation

INPUT:
```
User: I want to start using worktrees but I'm not sure how to organize them
```

EXPECTED FLOW:
1. INVOCATION DECISION TREE → PHASE 3 matches "start using worktrees" → INVOKE
2. STEP 1 → Assess current state (check if in git repo, count worktrees)
3. STEP 2 → Categorize as "MIGRATION"
4. STEP 3 → Route to STEP 4: Migration Strategy
5. STEP 4 → Provide migration plan with phases
6. STEP 11 → Output summary with recommendations

EXPECTED OUTPUT:
```
## Consultation Summary

You're looking to migrate to a worktree-based workflow. Based on your
current setup (single main repository), I recommend a phased approach.

## Recommendations

1. Start with a parallel directory structure
   - Rationale: Keeps main repo available while testing worktrees
   - Implementation: Use ~/worktrees/{project}/ for new worktrees
   - Command: /create:working-tree <branch> --mode feature

2. Establish naming convention early
   - Pattern: {project}-{branch-name}
   - Example: myapp-feature-auth, myapp-bugfix-login

3. Add metadata to all worktrees
   - Helps track purpose and status
   - Command: /adopt:working-tree --mode <mode> --description "..."

## Next Steps

1. [ ] Create directory structure: mkdir -p ~/worktrees/myproject
2. [ ] Create first feature worktree: /create:working-tree feature/test
3. [ ] Practice workflow: make changes, commit, push
4. [ ] Evaluate after 1 week, adjust as needed

## Relevant Commands

- /create:working-tree <branch> - Create new worktree
- /list:working-tree - List all worktrees
...
```

## TS002: Organization consultation with existing worktrees

INPUT:
```
User: Help me organize my worktrees, they're all over the place
```

EXPECTED FLOW:
1. INVOCATION DECISION TREE → PHASE 3 matches "organize.*worktrees" → INVOKE (SCORE: 0.35)
2. STEP 1 → Assess current state (find 5 worktrees in various locations)
3. STEP 2 → Categorize as "ORGANIZATION"
4. STEP 3 → Route to STEP 5: Organization Strategy
5. STEP 5 → Analyze current state, identify issues, provide recommendations
6. STEP 11 → Output summary

EXPECTED OUTPUT:
```
## Consultation Summary

Analysis of your 5 worktrees reveals several organizational opportunities:
- Worktrees scattered across 3 different directories
- Inconsistent naming patterns
- 2 worktrees lack metadata

## Recommendations

1. Consolidate to unified directory structure
   - Current: /Users/dev/proj1, /tmp/test, ~/code/feature
   - Recommended: ~/worktrees/myproject/{main,features,reviews}/
   - Rationale: Easier to find, manage, and backup

2. Standardize naming
   - Pattern: myproject-{branch-name}
   - Migrate: Rename using git worktree move (if needed)

3. Add metadata to all worktrees
   - 2 worktrees currently lack .ai-context.json
   - Command: /adopt:working-tree (run in each worktree)

## Next Steps

1. [ ] Create new directory structure: mkdir -p ~/worktrees/myproject/{features,reviews}
2. [ ] Plan migration order (least important first)
3. [ ] Move worktrees one at a time (git worktree move)
4. [ ] Add metadata: /adopt:working-tree
5. [ ] Update any scripts/aliases pointing to old locations

...
```

## TS003: Anti-pattern - operational request

INPUT:
```
User: Create a worktree for feature/auth
```

EXPECTED FLOW:
1. INVOCATION DECISION TREE → PHASE 2 matches "create.*worktree <branch-name>" → DO_NOT_INVOKE
2. System routes to /create:working-tree command instead

EXPECTED:
- Consultant NOT invoked
- /create:working-tree command invoked instead

## TS004: Troubleshooting broken worktree

INPUT:
```
User: I have a broken worktree that won't work, can you help?
```

EXPECTED FLOW:
1. INVOCATION DECISION TREE → PHASE 3 matches "worktree" + "broken" → INVOKE (SCORE: 0.20)
2. STEP 1 → Assess current state (run git worktree list)
3. STEP 2 → Categorize as "TROUBLESHOOTING"
4. STEP 3 → Route to STEP 6: Troubleshooting
5. STEP 6 → Run diagnostics, identify issue (worktree moved outside git)
6. STEP 11 → Provide solution and next steps

EXPECTED OUTPUT:
```
## Consultation Summary

Diagnosis: BROKEN_WORKTREE_LINK
Root Cause: Worktree directory moved or deleted outside of git

## Recommendations

1. Verify the issue
   - Command: git worktree list
   - Look for missing directories

2. Remove broken worktree link
   - Command: git worktree remove <name>
   - Or: git worktree prune (removes all broken links)

3. Recreate if needed
   - Command: /create:working-tree <branch>

## Next Steps

1. [ ] Run: git worktree list --porcelain
2. [ ] Identify broken worktree paths
3. [ ] Run: git worktree prune --dry-run (preview)
4. [ ] Run: git worktree prune (execute)
5. [ ] Recreate needed worktrees: /create:working-tree <branch>

## Prevention

- Always use /destroy:working-tree instead of manually deleting
- Don't move worktree directories manually
- Use git worktree move if relocation needed

...
```

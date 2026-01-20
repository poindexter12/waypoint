# Error Patterns Reference

Catalog of error patterns for the Working Tree Consultant agent. Load this reference when encountering errors or edge cases during consultation.

## PATTERN: not-in-git-repo

DETECTION:
- TRIGGER: User asks for worktree consultation but not in git repo
- CHECK: `git rev-parse --show-toplevel` fails

RESPONSE (exact):
```
Note: You're not currently in a git repository.

Worktree consultation can still proceed, but I won't be able to
analyze your current worktree setup.

Would you like to:
1. Continue with general worktree guidance
2. Navigate to a git repository first (then re-invoke)
```

CONTROL FLOW:
- ABORT: false (can continue with general guidance)
- ADJUST: Set context to "no-repo-available"
- CONTINUE: Proceed with educational/general guidance

## PATTERN: no-worktrees-exist

DETECTION:
- TRIGGER: User asks for organization help but has no worktrees yet
- CHECK: `git worktree list | wc -l` == 1 (only main)

RESPONSE (exact):
```
Current State: You have no additional worktrees (only main repository)

This is a great starting point! I recommend:
1. Learning about worktree benefits first
2. Planning your directory structure
3. Creating your first worktree

Would you like guidance on:
- [M] Migration strategy (moving to worktree workflow)
- [E] Educational overview (learning about worktrees)
- [W] Workflow design (planning your setup)
```

CONTROL FLOW:
- ABORT: false
- ADJUST: Route to migration or education
- CONTINUE: based on user choice

## PATTERN: ambiguous-request

DETECTION:
- TRIGGER: User request is too vague to categorize
- INDICATORS: category == "GENERAL" AND no clear topic

RESPONSE (exact):
```
I can help with various worktree topics:

1. **Migration** - Adopting worktrees for the first time
2. **Organization** - Structuring existing worktrees
3. **Troubleshooting** - Fixing worktree issues
4. **Workflow Design** - Designing custom workflows
5. **Best Practices** - Learning recommended patterns
6. **Education** - Understanding worktree concepts

Which area interests you most? Or describe your specific situation.
```

CONTROL FLOW:
- ABORT: false
- WAIT: for user clarification
- RETRY: STEP 2 with additional context

## PATTERN: wrong-tool-for-job

DETECTION:
- TRIGGER: User asks consultant to execute operations
- INDICATORS: "create a worktree for me", "list my worktrees", etc.

RESPONSE (exact):
```
I'm a consultant agent focused on strategy and guidance.

For actual worktree operations, use these commands:

- /create:working-tree <branch> - Create new worktree
- /list:working-tree - List existing worktrees
- /status:working-tree - Check current worktree
- /adopt:working-tree - Add metadata
- /destroy:working-tree <path> - Remove worktree

Would you like help understanding when or how to use these commands?
```

CONTROL FLOW:
- ABORT: false
- EDUCATE: Explain command usage
- DELEGATE: Suggest appropriate command

---
agent: 'agent'
description: Review committed code changes for issues.
---

# Code review

Review committed code changes for issues. DO NOT MODIFY ANY FILES except the review report.

## Scope

Find changed files:

```bash
git diff --name-only @{upstream}...HEAD
```

Only review committed changes from this list. Do not review staged, unstaged, or untracked files.

IGNORE these paths entirely:
- .github/prompts/*
- .github/instructions/*

## Review rules

Read these files completely before reviewing. Apply all checks from them:

- .github/instructions/code-review.instructions.md - domain-specific review checks
- .github/instructions/docker.instructions.md - Dockerfile standards
- .github/instructions/bash-scripting.instructions.md - shell script standards
- .github/instructions/markdown.instructions.md - Markdown standards

## Verification

Before reporting any issue, verify it exists in the actual file using `grep -n` or `sed -n`. Discard unconfirmed issues silently. Git diff output can be misleading due to line wrapping and display artifacts.

## Output

1. Write all issues to `tmp/copilot-review-{branch-name}.md` (replace `/` with `-` in branch name) with a severity summary and all issues with file paths and line numbers.
2. Present each issue ONE AT A TIME:

```markdown
## Issue N: [Brief title]

**File**: path/to/file:line
**Description**: What the issue is
**Suggestion**: How to fix it
```

After each issue, ask:

> How would you like to proceed?
> 1. Fix it for me
> 2. I'll fix it differently
> 3. More details please
> 4. Show me other options
> 5. Skip to next issue

---
name: replan-batch-tasks
description: "Reconcile a batch of downstream GitHub issues with the implementation just finished. Read the diff of what was built, enumerate the still-open downstream issues of a tracking issue, and propose and apply revised issue descriptions that reflect the decisions and surprises discovered during implementation. Use when asked to update stale issues after implementing part of a batch, sync a tracking issue's children with reality, or fix issue descriptions that drifted from the code."
license: MIT
---

# Sync a batch of downstream issues with the implementation

When you implement one issue in a batch, you learn things: an interface is shaped
differently than planned, a dependency moved, a decision was reversed, a name changed.
The downstream issues in that batch still describe the old plan. This skill drives the
reconciliation: read what was actually built, walk every still-open downstream issue,
and rewrite each description to match reality, one issue at a time and only with approval.

This is not specific to any one workflow, repository, or team. The tracking issue and the
downstream tasks can each live in any repository: the tracking issue in one repo, its tasks
scattered across several others, or any mix. Every command takes fully-qualified references
and resolves each repository independently, so a batch that spans repositories is normal.

## When to use

Use this skill when the user asks to:

- update or refresh downstream issues after finishing part of a batch,
- sync a tracking issue's sub-issues with what was learned during implementation,
- fix issue descriptions that have gone stale relative to the code.

You need a tracking issue (the batch parent) and a notion of "what we just built" (an open
or merged PR, the current branch, or an explicit commit range).

## The mechanics vs. the judgment

`scripts/replan-batch-tasks.sh` owns the deterministic `gh` plumbing so you do not have to
re-derive it: enumerating the batch, fetching bodies, computing the diff, and applying
gated writes. You own the judgment: deciding, per issue, what should change and why. Never
edit an issue body without showing the proposed change and getting approval first.

Run every command from the repository; it auto-detects the current repo via `gh`.

```
.github/skills/replan-batch-tasks/scripts/replan-batch-tasks.sh <command> [args]
```

An `<issue-ref>` is a full URL, an `owner/repo#123` slug, or a bare `#123` / `123`
(resolved against the current repo).

## The loop

### 1. Ground yourself in what was built

Read the actual diff, not your memory of the conversation.

```
scripts/replan-batch-tasks.sh diff                 # current branch vs merge-base with the default branch
scripts/replan-batch-tasks.sh diff --pr <number>   # a specific PR's diff
scripts/replan-batch-tasks.sh diff --range A..B    # an explicit commit range
```

Summarize, for yourself, the decisions and surprises that differ from the original plan:
renamed things, changed contracts, reversed choices, new constraints. These are what the
downstream issues need to absorb.

### 2. Enumerate the batch

```
scripts/replan-batch-tasks.sh batch <tracking-issue-ref>
```

This prints one JSON object per still-open downstream issue: `{repo, number, state, title, url}`.
It uses the native sub-issues API. Options:

- `--all` also includes closed issues (default is open-only, since closed issues are done).
- `--include-tasklist` also folds in `owner/repo#n` and `#n` references parsed from the
  tracking issue body, for batches that use a Markdown task list instead of native sub-issues.

The tracking issue itself is always excluded.

### 3. Reconcile each issue, one at a time

For each downstream issue, in order:

1. Read its current state:

   ```
   scripts/replan-batch-tasks.sh show <issue-ref>
   ```

2. Decide whether the implementation changes anything it describes. If nothing changed,
   say so and move on. Do not churn issues for the sake of it.

3. If it needs updating, draft the revised body to a scratch file under a repo-relative
   `./tmp/` directory (never `/tmp`), then present the change to the user as a diff of the
   old body against the new one, with a one-line rationale. Wait for approval before writing.

4. On approval, apply it:

   ```
   scripts/replan-batch-tasks.sh edit <issue-ref> --body-file ./tmp/<issue>-new-body.md
   ```

5. Optionally leave an audit-trail comment explaining why the description moved:

   ```
   scripts/replan-batch-tasks.sh comment <issue-ref> --body-file ./tmp/<issue>-note.md
   ```

Present issues one at a time and wait for a response before moving to the next; do not
batch several proposed edits into one message.

### 4. Update the tracking issue

The parent's own checklist or summary can drift too. Re-read it (`show <tracking-ref>`) and,
if its wording no longer matches the batch, propose and apply the same kind of edit.

## Guardrails

- **Approval gates every write.** `edit` and `comment` change GitHub state. Only run them
  after the user has approved the specific body.
- **Scope.** Default to still-open, not-yet-started issues. Leave closed or in-flight issues
  alone unless the user asks otherwise.
- **Cross-repo awareness.** Children may live in other repositories. Always use the
  fully-qualified `owner/repo#number` form when referring to an issue outside this repo.
- **Faithful edits.** Change only what the implementation actually invalidated. Preserve the
  issue's existing structure, headings, and acceptance criteria that are still correct.
- **No fabricated verification.** Describe what changed and why; do not claim testing or
  outcomes you did not observe.

## Requirements

- `gh` authenticated for every repository the batch spans.
- `jq` available on the `PATH`.

# Plan review prompt template (ACE-FCA)

This is the reproducible prompt the `ace-fca-review-plan` skill assembles and hands to
each reviewer model through the `adversarial-review` skill's non-PR plan path (two
reviewers from distinct non-host lineages). Fill every `<<<...>>>` placeholder from the
resolved plan and its companion research doc. Do not paraphrase the plan; paste it
verbatim, hedges and all. The reviewers have read-only access to the repo and must
verify each claim against the actual code, not trust the plan's description of it.

```
You are reviewing a PLAN for a non-trivial code change before any edits are made.
Repo: <<<REPO SLUG, e.g. github/moda-app-homepage>>> (checked out locally, read-only).
Verify every claim in the plan against the actual code. Do NOT trust the plan's
description of what the code does, what a value's type is, or who the consumers are.

Your job is to find what the author has not thought of. Assume the plan is wrong in at
least one of these ways, and prove it against the code:

1. Incomplete surface area. The plan lists a set of files/symbols to change, but a
   symbol it touches is also referenced, constructed, or re-exported somewhere the plan
   never mentions. Grep for every changed symbol and name the caller the plan missed.
2. An invariant a replaced primitive quietly enforced. The plan swaps or centralizes a
   helper/type/guard. What ordering, uniqueness, locking, caching, or single-writer
   property did the old shape enforce for free that the new shape drops?
3. A nullable/absent upstream field readers coalesce to zero (or a default). The plan
   assumes a response field, header, or config value is present and well-formed. What
   happens on the absent/unparseable/zero path? Is "missing" silently treated as a
   valid value?
4. A half-fixed sibling code path. The plan fixes one call site or one consumer but an
   equivalent sibling path (another route, another producer, a duplicated helper, a
   test double) keeps the old behavior. Find the sibling the plan leaves stale.
5. A silently dropped acceptance criterion. Cross-check the plan's acceptance-criteria
   coverage matrix and Change Impact Inventory against the companion research/issue.
   Name any criterion or invariant with no mapped step, or mapped to a step that does
   not actually satisfy it.
6. Hidden ordering or contamination. A gate/branch the plan removes or unconditions now
   runs in code paths it never used to. What downstream assumption breaks? For any
   concurrency claim (shared budget, shared cache, Promise.all fan-out), attack the
   read-modify-write: can two branches interleave and double-spend or lose an update?
7. Scope error in both directions. Flag "while we're here" refactors that belong in a
   separate PR, AND under-scoping where a stated constraint forces work the plan omits.
8. The opposite, simpler design. Is there a materially smaller shape (fewer new files,
   fewer exported functions, less defensive plumbing) that meets the same constraints?
   Argue for it. Default to deletion and to fewer abstractions, not preservation.
9. A wrong task boundary that ships a public no-op. Attack the decomposition, not just
   the internals. If this plan is one half of a coordinated set (a contract-first/stub
   task paired with a sibling that supplies the behavior, or this repo paired with a
   downstream consumer), ask what this task, merged alone, does in production. If it
   exposes a user-visible success that performs no work - a route returning 200 with a
   populated body while writing nothing and enforcing none of the sibling path's
   permission, scope, or lock gates - that is a public no-op that lies about success,
   and it is a GAP no matter how internally consistent the plan is. Also diff the
   contract surface (path, method, request schema, response vocabulary, status codes)
   across every artifact in the set; a disagreement between internally-consistent
   siblings (a differing path or response value) is a gap to reconcile now, not a seam
   to discover in review. Assume this ships to production exactly as planned: what
   regression ships, and should this task boundary exist at all?

For each finding: cite the file:line evidence, state the concrete failure it causes, and
propose the minimum-surface-area change. Default to deletion and scope-narrowing.

Then give a single calibrated CONFIDENCE VERDICT for the plan as a whole:
  - READY  — no material gap; the plan is safe to implement as written.
  - GAP    — at least one material gap must be resolved before implementation.
State which, in one line, followed by the one finding that most drives the verdict.

Don't be polite. If the plan is fundamentally muddled, propose a different plan. If you
find nothing material, say so plainly — do NOT manufacture findings to look thorough.

## Constraints (the author is intentionally keeping these — do NOT argue to undo them)

<<<PASTE the plan's "Key constraints" and "What we are not doing" sections verbatim.
If the plan lacks them, write "None stated" and treat that absence as itself a finding
under mistake class 7.>>>

## Plan (author's stated intent — pasted verbatim, hedges included)

<<<PASTE THE FULL TEXT OF THE RESOLVED PLAN DOCUMENT, UNEDITED>>>

## Surface area inventory (files the plan intends to touch)

<<<PASTE the file list extracted from the plan's Implementation phases, one line each
on what changes, cross-checked against the companion research Change Impact Inventory.>>>

## Companion context (read if useful; do NOT re-litigate settled decisions)

<<<LIST the companion research doc path and any decision docs the plan references, so the
reviewer can confirm nothing enumerated upstream was dropped.>>>
```

## Why this template differs from the stock diff review

- The **read-only codebase verification** is the load-bearing instruction: a plan states
  confidently what the code does; only a grep confirms it. That is what turns a
  "sounds plausible" plan into a verified one, which is the whole point of reviewing a
  plan rather than a diff.
- The **CONFIDENCE VERDICT** is added specifically for the ACE-FCA planning exit gate. It
  lets the caller compare an independent panel's READY/GAP verdict against the plan's own
  self-reported confidence statement, which is often miscalibrated after long iteration.

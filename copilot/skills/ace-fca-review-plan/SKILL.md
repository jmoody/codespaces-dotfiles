---
name: ace-fca-review-plan
description: Run an adversarial gap review on an ACE-FCA planning document before implementation, and optionally record the gaps in the plan's companion retrospective. Use when the user asks to "review this plan", "review the ace-fca plan", "find the gaps in this plan", "is this plan ready to implement", "adversarial review the plan", or wants an independent confidence check on a plan whose self-reported confidence they distrust. Resolves the newest plan under .github/ace-fca/plans (or an explicit path), assembles a plan-review prompt from the plan's own sections, delegates the model panel to the adversarial-review skill, and writes the findings back into the retro's "Plan adversarial review" section for continuous prompt improvement.
---

# ACE-FCA plan review — find the plan's gaps before you implement

A planning agent that has iterated on a plan for a long time is a poor judge of its own
plan: it reports "low confidence" or "< 80%" without being able to say what is missing,
because it is grading its own homework. This skill runs an **independent adversarial pass
on the plan itself** — the pre-edit half of `adversarial-review`, wired to the ACE-FCA
plan layout so it is reproducible in any repo that uses the workflow.

It does not review a diff and it does not implement anything. It reads a plan, verifies
the plan's claims against the real code, and returns a triaged gap list plus a calibrated
READY / GAP verdict you can weigh against the plan's own confidence statement.

## What this skill owns vs. what it delegates

- **This skill owns context assembly** — the part you cannot reproduce by hand: resolving
  which plan to review, extracting the four plan-review inputs from the plan's canonical
  ACE-FCA sections, and building the filled prompt from
  [`references/plan-review-prompt.md`](references/plan-review-prompt.md).
- **`adversarial-review` owns the panel mechanics** — non-host lineage selection, parallel
  launch, retry/fallback, consensus triage, and the chat-only reporting contract. This
  skill invokes it as a sub-step; it never re-implements model selection.

Because it is a plan (a non-PR artifact), the panel is **two reviewers from distinct
non-host lineages**. The Ponytail complexity lens never applies (it is post-edit-diff
only). Do not switch to a three-lineage panel — that is reserved for PR diffs of unknown
authorship, which a plan you wrote is not.

## When to use

- **Before the ACE-FCA planning exit gate**, as the independent check that the plan is
  actually High-confidence-ready rather than self-declared ready.
- **When the agent self-reports low confidence** in a plan after long iteration and cannot
  name why — this pass names the gap or clears the plan.
- **Before handing a plan to implementation**, especially when it touches shared helpers,
  persisted data, concurrency, or a coordinated set of changes.

**Don't bother** on a trivial plan (one file, no shared surface, no persisted-data or
concurrency implications) — the pass costs ~60-90s of agent time per reviewer.

## Process

### Step 1 — Resolve the plan

Run the resolver, which selects the newest plan (highest `NNNN` sequence prefix, mtime
tie-break) or uses an explicit path, and prints its companion research/retro docs:

```bash
"$SKILL_DIR/scripts/resolve-plan.sh" [PLAN_PATH]
# override the ACE-FCA root with -d/--dir when it is not .github/ace-fca
```

It emits `PLAN`, `RESEARCH`, `RETRO`, `SEQ`, `TOPIC`, `STATUS`, and `CONFIDENCE` as
`KEY=VALUE` lines. **Echo the resolved `PLAN` path and `TOPIC` to the user and let them
confirm or redirect before spending reviewer time** — picking the wrong plan wastes the
whole pass. If the repo has no `.github/ace-fca/plans` directory, ask the user for an
explicit plan path rather than guessing.

### Step 2 — Assemble the prompt

Read the resolved plan in full, then fill every placeholder in
[`references/plan-review-prompt.md`](references/plan-review-prompt.md) from the plan's own
canonical ACE-FCA sections:

- **Constraints** — the plan's `## Key constraints` and `## What we are not doing`
  sections, verbatim. If either is missing, say so; a plan without stated constraints is
  itself a finding.
- **Plan** — the entire plan document, unedited.
- **Surface area** — the file list from `## Implementation phases` (one line each on what
  changes), cross-checked against the research `Change Impact Inventory` so nothing
  enumerated upstream is dropped.
- **Companion context** — the `RESEARCH` path and any decision docs the plan references.

Headings vary slightly between repos and plan authors. Match on the section's intent, not
an exact string; when a canonical section is absent, fall back to pasting the whole plan
and note the missing section as a gap for the reviewers to weigh. Never invent content to
fill a placeholder.

### Step 3 — Delegate the panel to adversarial-review

Invoke the `adversarial-review` skill in its **non-PR plan mode** with the assembled
prompt and context as the artifact under review. Let it select the two non-host lineage
reviewers, launch them in parallel, and apply its retry/fallback rules. This skill adds no
model machinery of its own; if `adversarial-review` reports the pass incomplete (a reviewer
leg it could not fill), surface that verbatim rather than presenting a partial result.

### Step 4 — Triage and report

Follow `adversarial-review`'s triage and chat-only reporting contract: dedupe, promote to
consensus only what at least two reviewers independently raise, keep model attribution,
and sort into adopted / set aside / defended. Then add one ACE-FCA-specific line:

> **Confidence calibration** — panel verdict is READY / GAP (\<which\>); the plan's own
> stated confidence is \<CONFIDENCE from the resolver, or "not stated"\>. \<Agree or
> diverge, one sentence.\>

This is the payload the caller actually wants: an independent verdict to weigh against a
self-report they distrust. A GAP verdict is a signal to bounce the plan back to research or
planning, consistent with ACE-FCA's "under-confident and honest beats confident and wrong."

### Step 5 — Record the findings in the retro (continuous prompt improvement)

If the resolver returned a `RETRO` path, offer to write the pass into the plan's companion
retrospective so the gaps feed the continuous prompt-improvement effort, following
[`references/retro-writeback.md`](references/retro-writeback.md):

- Fill the retro's first-class `## Plan adversarial review` section (verdict, gaps found,
  confidence calibration, and planning-prompt improvement candidates) when it exists; append
  a dated section only for older retros created before the template carried it.
- **Confirm before writing.** Show the exact content and get a yes; this is the skill's one
  write, and it is opt-in. If the user declines, or `RETRO` is empty, keep the findings
  chat-only and say the writeback was skipped.
- The planning-prompt improvement bullets are candidates for a human to fold into
  `planning.prompt.md`. This skill records them; it never edits the prompt or the plan.

## Boundaries

**Will:**
- Resolve and review a single ACE-FCA plan, defaulting to the newest, in any repo that
  uses the `.github/ace-fca` layout.
- Verify the plan's claims against the real code through the reviewer panel.
- Return a triaged gap list and a calibrated READY / GAP verdict, inline in chat.
- With the user's confirmation, record the findings in the plan's companion retrospective's
  `## Plan adversarial review` section (its one and only write).

**Will not:**
- Implement the plan, edit the plan document, edit the planning prompt, or rewrite existing
  retro content.
- Write to any PR, issue, or branch, or write the retro without confirmation.
- Re-implement model/lineage selection — that is `adversarial-review`'s job.
- Use a three-lineage panel or the Ponytail lens; both are diff-only.
- Present an incomplete panel as complete.

## References

- [`references/plan-review-prompt.md`](references/plan-review-prompt.md) — the reproducible
  fill-in-the-blanks prompt, with ACE-FCA-tuned mistake classes and the confidence verdict.
- [`references/retro-writeback.md`](references/retro-writeback.md) — how to record findings
  in the companion retro's `## Plan adversarial review` section.
- [`scripts/resolve-plan.sh`](scripts/resolve-plan.sh) — plan resolver and companion-doc
  locator.

## Related skills

- `adversarial-review` — owns the reviewer panel this skill delegates to; use it directly
  for diffs, designs, and non-ACE-FCA plans.

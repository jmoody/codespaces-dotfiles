# Retro writeback format (ACE-FCA plan review)

When the resolved plan has a companion retrospective (`RETRO` from the resolver is
non-empty), the `ace-fca-review-plan` skill records the pass in that retro so the gap list
feeds the continuous prompt-improvement effort.

The retrospective template now carries a first-class `## Plan adversarial review` section
(with `### Verdict`, `### Gaps found`, `### Confidence calibration`, and
`### Planning-prompt improvement candidates` subsections). Prefer filling that section; fall
back to appending a dated section only for older retros created before the template gained
it.

## Rules

- **Fill the placeholder when it exists.** If the retro already has an (empty or
  placeholder-only) `## Plan adversarial review` section, replace its placeholder body with
  the findings under the existing subsections. Do not duplicate the section.
- **Otherwise append, dated.** If the retro has no such section, append one new
  `## Plan adversarial review (YYYY-MM-DD)` section at the end. Never edit, reorder, or
  delete existing retro content, and never touch the plan document or the planning prompt.
- **Confirm before writing.** Editing a git-tracked doc is a real change. Show the user the
  exact content to be written and get a yes first. If the user declines, keep the findings
  chat-only.
- **Skip cleanly when there is no retro.** If `RETRO` is empty, report the gaps in chat and
  say the retro writeback was skipped because no companion retro was found. Do not create
  one.
- **Follow the repo's markdown style.** Sentence-case headings, a blank line before and
  after every section, aligned tables, backticks for filenames and symbols.
- **Only recommend prompt changes; never apply them.** The planning-prompt improvement
  bullets are candidates for a human to fold into `planning.prompt.md`, not edits this skill
  makes.

## Content to write under the section

Fill the template's subsections (or, when appending, reproduce them under the dated
heading):

```markdown
### Verdict

READY or GAP - panel: <model A>, <model B>; reviewed YYYY-MM-DD.

### Gaps found

| # | Mistake class | Gap | Evidence | Drives verdict |
|---|---------------|-----|----------|----------------|
| 1 | Nullable upstream field | <one line> | `path/file.ts:120` | yes |

### Confidence calibration

Panel verdict: <READY or GAP>. Plan's stated confidence: <value, or "not stated">.
<One sentence on whether the panel agrees with or diverges from the self-report.>

### Planning-prompt improvement candidates

- <gap a stronger gate would have caught> - <the concrete `planning.prompt.md` or
  research-gate change that would have caught it>
```

When the pass found nothing material, keep `### Verdict` and `### Confidence calibration`
and leave `### Gaps found` and `### Planning-prompt improvement candidates` with a short
"None." line, so the clean result is still recorded.

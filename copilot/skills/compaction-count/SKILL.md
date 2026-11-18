---
name: compaction-count
description: Report Copilot CLI auto-compaction activity for a session (or rank all sessions), including how many times the context window was compacted and the token peak reached before each compaction. Use when the user asks "how many compactions", "is my session degrading", "when should I restart my session", "how full did the context get", or wants to watch compaction pressure that /context hides.
---

# Counting Copilot CLI compactions

Auto-compaction summarizes older conversation history to free up the context
window. The CLI triggers it at roughly 61% of the window (about 160k of a 264k
token window), so `/context` can never show a number in the 60-70% band: it
clips the window and resets the visible gauge the instant it gets there.

No slash command surfaces a running compaction counter, but every compaction
writes two events to the session's `events.jsonl`:

- `session.compaction_start`
- `session.compaction_complete`, which records `preCompactionTokens` (the real
  window peak just before the clip) and `preCompactionMessagesLength`.

Repeated compaction is the practical driver of session degradation
(instruction-skips, drift): each round replaces real messages with a lossy
summary. Watching the compaction count is a more direct early-warning signal
than the AI-credit total, which only correlates with it.

## Running the report

Resolve the installed skill dir, then call the bundled script. It is
**read-only** and only reads `events.jsonl` files.

```bash
# Resolve the installed skill dir, then call the script via "$SKILL_DIR/scripts/...".
SKILL_DIR=""  # start empty so the ${SKILL_DIR:?...} guard can't reuse a leaked value
for d in .github/skills/compaction-count "$HOME/.copilot/skills/compaction-count"; do
  [ -d "$d" ] && { SKILL_DIR="$d"; break; }
done
: "${SKILL_DIR:?compaction-count skill dir not found in .github/skills or ~/.copilot/skills}"

# Most recently modified session (the one you're likely in):
bash "$SKILL_DIR/scripts/compaction-count.sh"

# A specific session by UUID:
bash "$SKILL_DIR/scripts/compaction-count.sh" 088618b1-f95d-4054-a2e5-d1071dd93e5a

# Rank every session by compaction count (busiest first):
bash "$SKILL_DIR/scripts/compaction-count.sh" --all

# Only sessions with 3+ compactions:
bash "$SKILL_DIR/scripts/compaction-count.sh" --all --min 3

# Non-default window size for the percentage math:
bash "$SKILL_DIR/scripts/compaction-count.sh" --window 200000 <SESSION_ID>
```

The current session's UUID is the last path segment of the session-state
folder. When no session id is given, the script picks the most recently
modified session automatically.

## Interpreting the output

Single-session output shows the compaction count and each pre-compaction token
peak with its percentage of the window:

```
Session:     088618b1-f95d-4054-a2e5-d1071dd93e5a
Compactions: 9
Pre-compaction window peaks:
    160782 tokens  (61% of 264k)
    173233 tokens  (66% of 264k)
    ...
```

- **Compaction count** is the degradation signal. Two or three compactions is
  usually where quality starts to erode; consider restarting the session then.
- **Token peaks** clustering near ~61% confirm the auto-compaction threshold and
  reveal the real window fullness that `/context` never displays.

## How the count stays honest

The count matches the JSON `"type"` field
(`grep -cE '"type":"session\.compaction_start"'`), not a bare substring. This
matters because a session that merely *discusses* compaction, or whose tool
output embeds the literal string `session.compaction_start`, would otherwise be
counted as if it had compacted. Anchoring on the type field avoids those false
positives.

## Notes

- Set `COPILOT_SESSION_STATE_DIR` to point at a non-default session-state
  location; it defaults to `~/.copilot/session-state`.
- The script is read-only: it never writes to or modifies any session data.

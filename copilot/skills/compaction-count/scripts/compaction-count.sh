#!/usr/bin/env bash
#
# compaction-count.sh - Report auto-compaction activity for Copilot CLI sessions.
#
# Auto-compaction is not surfaced as a live counter in any slash command, but every
# compaction writes `session.compaction_start` / `session.compaction_complete` events
# to a session's events.jsonl. The `compaction_complete` event records
# `preCompactionTokens` - the real window peak just before the window was clipped,
# which `/context` never shows because it resets the visible gauge on compaction.
#
# This script counts real compactions (anchored on the JSON "type" field so literal
# occurrences of the string inside message or tool-output text can't create false
# positives) and prints each pre-compaction token peak.

set -euo pipefail

readonly WINDOW_TOKENS_DEFAULT=264000
STATE_DIR="${COPILOT_SESSION_STATE_DIR:-$HOME/.copilot/session-state}"

usage() {
  cat <<'EOF'
Usage: compaction-count.sh [--window N] [--all [--min N]] [SESSION_ID]

Report Copilot CLI auto-compaction activity.

Arguments:
  SESSION_ID     Session UUID to inspect. Defaults to the most recently
                 modified session under the session-state directory.

Options:
  --all          Rank every session by compaction count (descending).
  --min N        With --all, only list sessions with at least N compactions
                 (default: 1).
  --window N     Context window size in tokens for percentage math
                 (default: 264000).
  -h, --help     Show this help.

Environment:
  COPILOT_SESSION_STATE_DIR  Override the session-state directory location.
EOF
}

# Count real compaction_start events by matching the JSON type field only.
count_compactions() {
  local events_file="$1"
  grep -cE '"type":"session\.compaction_start"' "$events_file" 2>/dev/null || true
}

# Emit pre-compaction token peaks, one per line.
token_peaks() {
  local events_file="$1"
  grep -hE '"type":"session\.compaction_complete"' "$events_file" 2>/dev/null \
    | grep -oE '"preCompactionTokens":[0-9]+' \
    | grep -oE '[0-9]+' || true
}

report_one() {
  local sid="$1" window="$2"
  local events_file="$STATE_DIR/$sid/events.jsonl"

  if [[ ! -f "$events_file" ]]; then
    echo "No events.jsonl found for session: $sid" >&2
    echo "Looked in: $events_file" >&2
    return 1
  fi

  local count
  count="$(count_compactions "$events_file")"
  count="${count:-0}"

  echo "Session:     $sid"
  echo "Compactions: $count"

  if [[ "$count" -eq 0 ]]; then
    echo "(no compactions yet)"
    return 0
  fi

  echo "Pre-compaction window peaks:"
  local tokens
  while IFS= read -r tokens; do
    [[ -z "$tokens" ]] && continue
    awk -v t="$tokens" -v w="$window" \
      'BEGIN { printf "  %8d tokens  (%.0f%% of %dk)\n", t, (t/w)*100, w/1000 }'
  done < <(token_peaks "$events_file")
}

report_all() {
  local window="$1" min="$2"
  local events_file sid count
  local -a rows=()

  for events_file in "$STATE_DIR"/*/events.jsonl; do
    [[ -f "$events_file" ]] || continue
    count="$(count_compactions "$events_file")"
    count="${count:-0}"
    [[ "$count" -lt "$min" ]] && continue
    sid="$(basename "$(dirname "$events_file")")"
    rows+=("$(printf '%4d  %s' "$count" "$sid")")
  done

  if [[ "${#rows[@]}" -eq 0 ]]; then
    echo "No sessions with >= $min compaction(s) found under $STATE_DIR."
    return 0
  fi

  printf '%s\n' "COMPS  SESSION"
  printf '%s\n' "${rows[@]}" | sort -rn
}

main() {
  local window="$WINDOW_TOKENS_DEFAULT"
  local all=false min=1
  local session_id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all) all=true; shift ;;
      --min) min="${2:?--min requires a value}"; shift 2 ;;
      --window) window="${2:?--window requires a value}"; shift 2 ;;
      -h|--help) usage; return 0 ;;
      -*) echo "Unknown option: $1" >&2; usage >&2; return 2 ;;
      *) session_id="$1"; shift ;;
    esac
  done

  if [[ ! -d "$STATE_DIR" ]]; then
    echo "Session-state directory not found: $STATE_DIR" >&2
    return 1
  fi

  if [[ "$all" == true ]]; then
    report_all "$window" "$min"
    return
  fi

  if [[ -z "$session_id" ]]; then
    # Default to the most recently modified session.
    local _sorted
    _sorted="$(
      for d in "$STATE_DIR"/*/; do
        [[ -f "$d/events.jsonl" ]] || continue
        printf '%s\t%s\n' \
          "$(stat -c '%Y' "$d/events.jsonl" 2>/dev/null || stat -f '%m' "$d/events.jsonl")" \
          "$(basename "$d")"
      done | sort -rn
    )"
    session_id="$(printf '%s\n' "$_sorted" | awk -F'\t' 'NR==1 {print $2}')"
    if [[ -z "$session_id" ]]; then
      echo "No sessions found under $STATE_DIR." >&2
      return 1
    fi
    echo "(no session id given; using most recent: $session_id)"
    echo
  fi

  report_one "$session_id" "$window"
}

main "$@"

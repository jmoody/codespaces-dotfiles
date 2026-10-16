#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat << EOF
Usage: $0 [OPTIONS] [PLAN_PATH]

Resolve an ACE-FCA planning document and its companion research/retro docs, then
print machine-readable KEY=VALUE lines for the adversarial plan review to consume.

If PLAN_PATH is given, that plan is used verbatim. Otherwise the most recent plan
in the ACE-FCA plans directory is selected: highest zero-padded NNNN sequence
prefix wins, with most-recently-modified as the tie-break.

OPTIONS:
  -d, --dir DIR   ACE-FCA root directory (default: .github/ace-fca)
  -h, --help      Show this help message

OUTPUT KEYS:
  PLAN            Absolute path to the resolved plan document
  RESEARCH        Absolute path to the companion research doc, or empty
  RETRO           Absolute path to the companion retrospective doc, or empty
  SEQ             The NNNN sequence prefix, or empty when the plan is unnumbered
  TOPIC           The plan's frontmatter topic, or its first H1, or the basename
  STATUS          The plan's frontmatter status, or empty
  CONFIDENCE      First line mentioning a confidence rating, or empty
EOF
}

log_error() {
  echo "[ERROR] $*" >&2
}

frontmatter_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm {
      line = $0
      sub(/^[ \t]*/, "", line)
      if (index(line, key ":") == 1) {
        sub(/^[^:]*:[ \t]*/, "", line)
        gsub(/^["'"'"']|["'"'"']$/, "", line)
        print line
        exit
      }
    }
  ' "$file"
}

first_h1() {
  local file="$1"
  awk '/^# / { sub(/^# +/, ""); print; exit }' "$file"
}

confidence_line() {
  local file="$1"
  grep -iE 'confidence' "$file" | head -n 1 | sed 's/^[[:space:]]*//' || true
}

companion() {
  local dir="$1" seq="$2"
  [[ -z "$seq" || ! -d "$dir" ]] && return 0
  local match
  match="$(find "$dir" -maxdepth 1 -type f -name "${seq}-*.md" 2>/dev/null | sort | head -n 1)"
  [[ -n "$match" ]] && realpath "$match"
}

select_latest_plan() {
  local plans_dir="$1"
  local numbered unnumbered
  numbered="$(find "$plans_dir" -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null \
    | sed -E 's#.*/([0-9]+)-.*#\1\t&#' | sort -r | head -n 1 | cut -f2- || true)"
  if [[ -n "$numbered" ]]; then
    realpath "$numbered"
    return 0
  fi
  unnumbered="$(find "$plans_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null \
    | while read -r f; do printf '%s\t%s\n' "$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f")" "$f"; done \
    | sort -rn | head -n 1 | cut -f2- || true)"
  [[ -n "$unnumbered" ]] && realpath "$unnumbered"
}

main() {
  local ace_dir=".github/ace-fca"
  local plan_arg=""

  while getopts "hd:-:" opt; do
    case $opt in
      h) usage; exit 0 ;;
      d) ace_dir="$OPTARG" ;;
      -) case $OPTARG in
           help) usage; exit 0 ;;
           dir) ace_dir="${!OPTIND}"; OPTIND=$((OPTIND + 1)) ;;
           dir=*) ace_dir="${OPTARG#*=}" ;;
           *) log_error "Unknown option: --$OPTARG"; exit 1 ;;
         esac ;;
      *) log_error "Invalid option"; exit 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  [[ $# -gt 0 ]] && plan_arg="$1"

  local plan
  if [[ -n "$plan_arg" ]]; then
    [[ -f "$plan_arg" ]] || { log_error "Plan not found: $plan_arg"; exit 1; }
    plan="$(realpath "$plan_arg")"
  else
    local plans_dir="${ace_dir}/plans"
    [[ -d "$plans_dir" ]] || { log_error "No plans directory at ${plans_dir}. Pass an explicit PLAN_PATH."; exit 1; }
    plan="$(select_latest_plan "$plans_dir")"
    [[ -n "$plan" ]] || { log_error "No plan documents found under ${plans_dir}."; exit 1; }
  fi

  local seq topic status research retro confidence
  seq="$(basename "$plan" | sed -nE 's/^([0-9]+)-.*/\1/p')"
  topic="$(frontmatter_value "$plan" topic)"
  [[ -z "$topic" ]] && topic="$(first_h1 "$plan")"
  [[ -z "$topic" ]] && topic="$(basename "$plan" .md)"
  status="$(frontmatter_value "$plan" status)"
  research="$(companion "${ace_dir}/research" "$seq")"
  retro="$(companion "${ace_dir}/retros" "$seq")"
  confidence="$(confidence_line "$plan")"

  printf 'PLAN=%s\n' "$plan"
  printf 'RESEARCH=%s\n' "${research:-}"
  printf 'RETRO=%s\n' "${retro:-}"
  printf 'SEQ=%s\n' "${seq:-}"
  printf 'TOPIC=%s\n' "${topic:-}"
  printf 'STATUS=%s\n' "${status:-}"
  printf 'CONFIDENCE=%s\n' "${confidence:-}"
}

main "$@"

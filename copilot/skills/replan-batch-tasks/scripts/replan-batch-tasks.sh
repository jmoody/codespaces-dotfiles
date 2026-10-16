#!/usr/bin/env bash

set -euo pipefail

log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

usage() {
  cat << EOF
Usage: $0 <command> [args]

Mechanize the gh plumbing for reconciling a batch of downstream issues with the
implementation just finished. The agent supplies the judgment (what each issue
body should now say); this script supplies deterministic reads and gated writes.

Commands:
  batch <issue-ref> [--all] [--include-tasklist]
                                Enumerate the downstream issues of a tracking issue as
                                JSON lines: {repo, number, state, title, url}. Uses the
                                native sub-issues API. Open-only by default; --all keeps
                                closed issues too. --include-tasklist also folds in issue
                                references parsed from the tracking issue body task list.
  show <issue-ref>              Print an issue's current title and raw body (for the agent
                                to reconcile against the implementation).
  body <issue-ref>              Print only the raw issue body (no title), for diffing.
  diff [--pr N] [--base REF] [--range A..B]
                                Print the implementation diff. Default: current branch
                                against its merge-base with the repo default branch. --pr uses
                                a PR's diff, --base diffs against merge-base with REF, --range is literal.
  edit <issue-ref> --body-file FILE
                                Replace the issue body with FILE. This is the write step;
                                only run it after the change has been approved.
  comment <issue-ref> --body-file FILE
                                Add a comment to the issue (use for an audit trail of why
                                the body was revised).

Options:
  -h, --help                    Show this help message.

An <issue-ref> is a full URL (https://github.com/owner/repo/issues/123),
an owner/repo#123 slug, or a bare #123 / 123 resolved against the current repo.

Requires: gh (authenticated) and jq. The current repo is auto-detected via gh.
EOF
}

require_tools() {
  local tool
  for tool in gh jq; do
    if ! command -v "${tool}" > /dev/null 2>&1; then
      log_error "required tool not found: ${tool}"
      exit 1
    fi
  done
}

current_repo() {
  gh repo view --json nameWithOwner --jq .nameWithOwner
}

default_branch() {
  gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
}

# Parse an issue reference into "owner repo number".
parse_ref() {
  local ref="$1"
  local owner="" repo="" number=""

  if [[ "${ref}" =~ ^https?://github\.com/([^/]+)/([^/]+)/issues/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    number="${BASH_REMATCH[3]}"
  elif [[ "${ref}" =~ ^([^/#]+)/([^/#]+)#([0-9]+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    number="${BASH_REMATCH[3]}"
  elif [[ "${ref}" =~ ^#?([0-9]+)$ ]]; then
    local slug
    slug="$(current_repo)"
    owner="${slug%%/*}"
    repo="${slug##*/}"
    number="${BASH_REMATCH[1]}"
  else
    log_error "unrecognized issue reference: ${ref}"
    return 1
  fi

  printf '%s %s %s\n' "${owner}" "${repo}" "${number}"
}

# Emit JSON lines for the native sub-issues of a tracking issue.
sub_issues_json() {
  local owner="$1" repo="$2" number="$3"
  gh api --paginate "repos/${owner}/${repo}/issues/${number}/sub_issues" \
    --jq '.[] | {repo: .repository.full_name, number: .number, state: .state, title: .title, url: .html_url}'
}

# Emit JSON lines for owner/repo#num and bare #num references found in a task list body.
tasklist_json() {
  local owner="$1" repo="$2" number="$3"
  local body
  body="$(gh api "repos/${owner}/${repo}/issues/${number}" --jq '.body // ""')"

  # Cross-repo references: owner/repo#num
  printf '%s\n' "${body}" \
    | grep -oE '[A-Za-z0-9._-]+/[A-Za-z0-9._-]+#[0-9]+' \
    | while IFS='#' read -r slug refnum; do
        fetch_issue_json "${slug%%/*}" "${slug##*/}" "${refnum}"
      done

  # Bare references: #num, resolved against the tracking issue's own repo. Strip
  # any that were part of an owner/repo#num match by requiring a non-slash lead.
  printf '%s\n' "${body}" \
    | grep -oE '(^|[^/A-Za-z0-9._-])#[0-9]+' \
    | grep -oE '#[0-9]+' \
    | while IFS='#' read -r _ refnum; do
        fetch_issue_json "${owner}" "${repo}" "${refnum}"
      done
}

fetch_issue_json() {
  local owner="$1" repo="$2" number="$3"
  gh api "repos/${owner}/${repo}/issues/${number}" \
    --jq '{repo: .repository_url | sub("^.*/repos/"; ""), number: .number, state: .state, title: .title, url: .html_url}' \
    2>/dev/null || log_error "could not fetch ${owner}/${repo}#${number} (skipped)"
}

cmd_batch() {
  local ref="" all=false include_tasklist=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all) all=true; shift ;;
      --include-tasklist) include_tasklist=true; shift ;;
      -h|--help) usage; exit 0 ;;
      -*) log_error "unknown option: $1"; exit 1 ;;
      *) ref="$1"; shift ;;
    esac
  done
  if [[ -z "${ref}" ]]; then
    log_error "batch requires an <issue-ref>"
    exit 1
  fi

  local parsed owner repo number
  parsed="$(parse_ref "${ref}")"
  read -r owner repo number <<< "${parsed}"

  {
    sub_issues_json "${owner}" "${repo}" "${number}"
    if [[ "${include_tasklist}" == true ]]; then
      tasklist_json "${owner}" "${repo}" "${number}"
    fi
  } | jq -c 'select(.number != '"${number}"')' \
    | jq -s 'unique_by([.repo, .number]) | .[]' -c \
    | if [[ "${all}" == true ]]; then cat; else jq -c 'select(.state == "open")'; fi
}

cmd_show() {
  local ref="${1:?show requires an <issue-ref>}"
  local parsed owner repo number
  parsed="$(parse_ref "${ref}")"
  read -r owner repo number <<< "${parsed}"
  gh api "repos/${owner}/${repo}/issues/${number}" \
    --jq '"# " + .title + "\n\n" + (.body // "")'
}

cmd_body() {
  local ref="${1:?body requires an <issue-ref>}"
  local parsed owner repo number
  parsed="$(parse_ref "${ref}")"
  read -r owner repo number <<< "${parsed}"
  gh api "repos/${owner}/${repo}/issues/${number}" --jq '.body // ""'
}

cmd_diff() {
  local mode="branch" pr="" base="" range=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr) mode="pr"; pr="${2:?--pr requires a number}"; shift 2 ;;
      --base) mode="branch"; base="${2:?--base requires a ref}"; shift 2 ;;
      --range) mode="range"; range="${2:?--range requires A..B}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) log_error "unknown option: $1"; exit 1 ;;
    esac
  done

  case "${mode}" in
    pr) gh pr diff "${pr}" ;;
    range) git --no-pager diff "${range}" ;;
    branch)
      local target mergebase
      target="${base:-$(default_branch)}"
      mergebase="$(git merge-base HEAD "${target}")"
      git --no-pager diff "${mergebase}...HEAD"
      ;;
  esac
}

cmd_edit() {
  local ref="" body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body-file) body_file="${2:?--body-file requires a path}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      -*) log_error "unknown option: $1"; exit 1 ;;
      *) ref="$1"; shift ;;
    esac
  done
  if [[ -z "${ref}" || -z "${body_file}" ]]; then
    log_error "edit requires <issue-ref> and --body-file FILE"
    exit 1
  fi
  if [[ ! -f "${body_file}" ]]; then
    log_error "body file not found: ${body_file}"
    exit 1
  fi

  local parsed owner repo number
  parsed="$(parse_ref "${ref}")"
  read -r owner repo number <<< "${parsed}"

  gh api --method PATCH "repos/${owner}/${repo}/issues/${number}" \
    --field "body=@${body_file}" \
    --jq '"[OK] updated " + .html_url'
}

cmd_comment() {
  local ref="" body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body-file) body_file="${2:?--body-file requires a path}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      -*) log_error "unknown option: $1"; exit 1 ;;
      *) ref="$1"; shift ;;
    esac
  done
  if [[ -z "${ref}" || -z "${body_file}" ]]; then
    log_error "comment requires <issue-ref> and --body-file FILE"
    exit 1
  fi
  if [[ ! -f "${body_file}" ]]; then
    log_error "body file not found: ${body_file}"
    exit 1
  fi

  local parsed owner repo number
  parsed="$(parse_ref "${ref}")"
  read -r owner repo number <<< "${parsed}"

  gh api --method POST "repos/${owner}/${repo}/issues/${number}/comments" \
    --field "body=@${body_file}" \
    --jq '"[OK] commented " + .html_url'
}

main() {
  require_tools

  local command="${1:-}"
  if [[ -z "${command}" ]]; then
    usage
    exit 1
  fi
  shift || true

  case "${command}" in
    batch) cmd_batch "$@" ;;
    show) cmd_show "$@" ;;
    body) cmd_body "$@" ;;
    diff) cmd_diff "$@" ;;
    edit) cmd_edit "$@" ;;
    comment) cmd_comment "$@" ;;
    -h|--help|help) usage; exit 0 ;;
    *) log_error "unknown command: ${command}"; usage; exit 1 ;;
  esac
}

main "$@"

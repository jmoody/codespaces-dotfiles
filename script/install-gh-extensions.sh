#!/usr/bin/env bash

set -euo pipefail

readonly EXTENSIONS=(
  "github/gh-stack"
)

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Install the GitHub CLI extensions that are not installed already.

OPTIONS:
  -h, --help  Show this help message

EOF
}

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

main() {
  local installed extension
  local failures=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage >&2
        exit 1
        ;;
    esac
  done

  if ! command -v gh > /dev/null 2>&1; then
    log_error "gh is not available"
    return 1
  fi

  if ! installed="$(gh extension list)"; then
    log_error "Failed to list the installed gh extensions"
    return 1
  fi

  for extension in "${EXTENSIONS[@]}"; do
    if awk -v repo="${extension}" -F'\t' '$2 == repo { found = 1 } END { exit !found }' <<< "${installed}"; then
      log_info "${extension} is already installed"
      continue
    fi

    log_info "Installing ${extension}"
    if ! gh extension install "${extension}"; then
      log_warn "Failed to install ${extension}"
      failures=$((failures + 1))
    fi
  done

  if [[ ${failures} -gt 0 ]]; then
    log_warn "${failures} gh extension(s) failed to install"
    return 1
  fi
}

main "$@"

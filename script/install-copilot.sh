#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly DOTFILES_DIR

readonly COPILOT_SRC="${DOTFILES_DIR}/copilot"
readonly COPILOT_HOME="${HOME}/.copilot"
readonly COPILOT_PACKAGE="@github/copilot@prerelease"

readonly VENDORED_SKILLS=(
  "ace-fca-review-plan"
  "adr-author"
  "fix-markdown"
  "replan-batch-tasks"
)

readonly MANAGED_SKILLS=(
  "github/agent-config skills/adversarial-review"
  "DietrichGebert/ponytail skills/ponytail-review"
  "datadog-labs/agent-skills dd-pup"
)

readonly PLUGINS=(
  "port@agent-config"
  "gho11y@agent-config"
  "slack-mcp@github-slack-mcp"
)

failures=0

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Install the GitHub Copilot CLI configuration into \${HOME}/.copilot.

Renders the instruction file, copies settings.json, symlinks mcp-config.json,
symlinks the skills that this repository vendors, then installs the skills
and plugins that come from GitHub.

The CLI rewrites settings.json when it installs a plugin, so that file is a
copy. A symlink does not survive the rewrite.

The steps that need the network warn instead of failing, so a container
without credentials still gets the local files.

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

render_instructions() {
  local target="${COPILOT_HOME}/copilot-instructions.md"
  local template="${COPILOT_SRC}/copilot-instructions.md.in"

  if [[ ! -f "${template}" ]]; then
    log_error "Missing ${template}"
    return 1
  fi

  log_info "${template} => ${target}"
  sed "s|@HOME@|${HOME}|g" "${template}" > "${target}"
}

link_file() {
  local source="${COPILOT_SRC}/$1"
  local target="${COPILOT_HOME}/$1"

  if [[ ! -e "${source}" ]]; then
    log_error "Missing ${source}"
    return 1
  fi

  log_info "${source} => ${target}"
  ln -sfn "${source}" "${target}"
}

copy_file() {
  local source="${COPILOT_SRC}/$1"
  local target="${COPILOT_HOME}/$1"

  if [[ ! -e "${source}" ]]; then
    log_error "Missing ${source}"
    return 1
  fi

  log_info "${source} => ${target}"
  rm -f "${target}"
  install -m 600 "${source}" "${target}"
}

link_vendored_skills() {
  local skill

  for skill in "${VENDORED_SKILLS[@]}"; do
    link_file "skills/${skill}"
  done
}

install_copilot_cli() {
  if ! command -v npm > /dev/null 2>&1; then
    log_warn "npm is not available, skipping the Copilot CLI install"
    return 1
  fi

  log_info "Installing ${COPILOT_PACKAGE} with npm"
  npm install -g "${COPILOT_PACKAGE}"
}

setup_git_credentials() {
  local key="credential.https://github.com.helper"

  if ! command -v gh > /dev/null 2>&1; then
    log_warn "gh is not available, skipping the git credential helper"
    return 1
  fi

  if git config --global --get "${key}" > /dev/null 2>&1; then
    log_info "github.com already has a git credential helper"
    return 0
  fi

  log_info "Setting gh as the git credential helper for github.com"
  git config --global "${key}" "!gh auth git-credential"
}

install_managed_skills() {
  local entry repo path

  if ! command -v gh > /dev/null 2>&1; then
    log_warn "gh is not available, skipping the managed skills"
    return 1
  fi

  for entry in "${MANAGED_SKILLS[@]}"; do
    read -r repo path <<< "${entry}"
    log_info "Installing skill ${path} from ${repo}"
    if ! gh skill install "${repo}" "${path}" \
      --agent github-copilot --scope user --force; then
      log_warn "Failed to install ${path} from ${repo}"
      failures=$((failures + 1))
    fi
  done
}

install_plugins() {
  local plugin

  if ! command -v copilot > /dev/null 2>&1; then
    log_warn "The Copilot CLI is not available, skipping the plugins"
    return 1
  fi

  log_info "The marketplaces are private repositories that git must clone"
  setup_git_credentials || failures=$((failures + 1))

  for plugin in "${PLUGINS[@]}"; do
    log_info "Installing plugin ${plugin}"
    if ! copilot plugin install "${plugin}"; then
      log_warn "Failed to install ${plugin}"
      failures=$((failures + 1))
    fi
  done
}

main() {
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

  mkdir -p "${COPILOT_HOME}/skills"

  render_instructions
  copy_file "settings.json"
  link_file "mcp-config.json"
  link_vendored_skills

  install_copilot_cli || failures=$((failures + 1))
  install_managed_skills || true
  install_plugins || true

  if [[ ${failures} -gt 0 ]]; then
    log_warn "${failures} Copilot step(s) failed, see the warnings above"
    return 1
  fi

  log_info "Copilot configuration is installed"
}

main "$@"

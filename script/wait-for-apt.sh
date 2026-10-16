#!/usr/bin/env bash

# Codespaces starts background apt processes while the container is created.
# They hold the apt locks, so apt-get must be retried until the lock is free.

apt_get_retry() {
  local max_wait=300
  local interval=5
  local elapsed=0
  local output
  local status

  while true; do
    if output="$(sudo apt-get "$@" 2>&1)"; then
      printf '%s\n' "${output}"
      return 0
    else
      status=$?
    fi

    if ! grep -qE 'Could not get lock|Unable to lock|Unable to acquire the dpkg frontend lock' <<< "${output}"; then
      printf '%s\n' "${output}" >&2
      error "apt-get $* failed with status ${status}" >&2
      return "${status}"
    fi

    if [[ "${elapsed}" -ge "${max_wait}" ]]; then
      printf '%s\n' "${output}" >&2
      error "apt-get $* could not get the apt lock within ${max_wait}s" >&2
      return "${status}"
    fi

    info "apt lock is held, retrying apt-get $* in ${interval}s (${elapsed}s elapsed)"
    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done
}

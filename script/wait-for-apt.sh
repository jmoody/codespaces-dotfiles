#!/usr/bin/env bash

# Wait for apt locks to be released
# This is needed in Codespaces where background apt processes may be running

wait_for_apt_lock() {
  local max_wait=300  # 5 minutes
  local wait_interval=5
  local elapsed=0
  
  info "Checking for apt locks..."
  
  while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    
    if [ $elapsed -ge $max_wait ]; then
      echo "WARNING: Timeout waiting for apt locks after ${max_wait}s, proceeding anyway..."
      return 1
    fi
    
    info "Waiting for apt locks to be released... (${elapsed}s elapsed)"
    sleep $wait_interval
    elapsed=$((elapsed + wait_interval))
  done
  
  info "Apt locks are free, proceeding..."
  return 0
}

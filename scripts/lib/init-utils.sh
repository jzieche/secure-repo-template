#!/usr/bin/env bash
set -u
# set -e is not used to allow functions to return non-zero values without exiting

# Utility library for repository initialization
# Exports functions for logging, user prompts, JSON validation, checkpointing, and cleanup

# init_log(message)
# Log with [INIT] prefix to stderr
init_log() {
  local message="$1"
  printf '[INIT] %s\n' "$message" >&2
}

# init_error(message)
# Log error with [ERROR] prefix to stderr and set exit code 1
init_error() {
  local message="$1"
  printf '[ERROR] %s\n' "$message" >&2
  return 1
}

# init_warn(message)
# Log warning with [WARN] prefix to stderr
init_warn() {
  local message="$1"
  printf '[WARN] %s\n' "$message" >&2
}

# prompt_user(prompt_text, default_value)
# Interactive prompt, returns user input or default
# Usage: response=$(prompt_user "Enter name" "default-name")
prompt_user() {
  local prompt_text="$1"
  local default_value="$2"
  local user_input

  if [[ -n "$default_value" ]]; then
    printf '%s [%s]: ' "$prompt_text" "$default_value" >&2
  else
    printf '%s: ' "$prompt_text" >&2
  fi

  read -r user_input || true
  
  if [[ -z "$user_input" ]]; then
    printf '%s' "$default_value"
  else
    printf '%s' "$user_input"
  fi
}

# prompt_required(prompt_text)
# Interactive prompt for required values (must be non-empty, loop until valid)
# Usage: value=$(prompt_required "Enter required value")
prompt_required() {
  local prompt_text="$1"
  local user_input

  while true; do
    printf '%s (required): ' "$prompt_text" >&2
    read -r user_input || true
    
    if [[ -n "$user_input" ]]; then
      printf '%s' "$user_input"
      break
    else
      init_warn "Input is required, please try again"
    fi
  done
}

# validate_json(json_string)
# Returns 0 if valid JSON, 1 if not
validate_json() {
  local json_string="$1"
  
  if command -v jq >/dev/null 2>&1; then
    if printf '%s' "$json_string" | jq empty 2>/dev/null; then
      return 0
    else
      return 1
    fi
  else
    # Fallback: basic validation using grep
    if printf '%s' "$json_string" | grep -qE '^\s*(\{|\[)'; then
      return 0
    else
      return 1
    fi
  fi
}

# save_checkpoint(phase_name, variables_json)
# Save state to .init-state.json with phase, variables, and timestamp
save_checkpoint() {
  local phase_name="$1"
  local variables_json="$2"
  local timestamp
  
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Validate input JSON
  if ! validate_json "$variables_json"; then
    init_error "Invalid JSON in variables_json"
    return 1
  fi
  
  # Create checkpoint JSON using jq if available
  if command -v jq >/dev/null 2>&1; then
    local checkpoint
    checkpoint=$(jq -n \
      --arg phase "$phase_name" \
      --arg ts "$timestamp" \
      --argjson vars "$variables_json" \
      '{phase: $phase, timestamp: $ts, variables: $vars}')
    printf '%s' "$checkpoint" > .init-state.json
  else
    # Fallback: basic JSON construction
    printf '{"phase":"%s","timestamp":"%s","variables":%s}' \
      "$phase_name" "$timestamp" "$variables_json" > .init-state.json
  fi
  
  init_log "Checkpoint saved: phase=$phase_name"
  return 0
}

# load_checkpoint()
# Load and print JSON from .init-state.json, return 0 if exists, 1 if not
load_checkpoint() {
  if [[ ! -f .init-state.json ]]; then
    return 1
  fi
  
  if command -v jq >/dev/null 2>&1; then
    jq . .init-state.json
  else
    cat .init-state.json
  fi
  
  return 0
}

# checkpoint_exists()
# Return 0 if .init-state.json exists, 1 if not
checkpoint_exists() {
  if [[ -f .init-state.json ]]; then
    return 0
  else
    return 1
  fi
}

# cleanup_template_files()
# Remove plan-githubSecureRepoTemplate.prompt.md and docs/USING-THE-TEMPLATE.md if they exist
cleanup_template_files() {
  local files_removed=0
  
  if [[ -f plan-githubSecureRepoTemplate.prompt.md ]]; then
    rm -f plan-githubSecureRepoTemplate.prompt.md
    init_log "Removed plan-githubSecureRepoTemplate.prompt.md"
    ((files_removed++))
  fi
  
  if [[ -f docs/USING-THE-TEMPLATE.md ]]; then
    rm -f docs/USING-THE-TEMPLATE.md
    init_log "Removed docs/USING-THE-TEMPLATE.md"
    ((files_removed++))
  fi
  
  if [[ $files_removed -gt 0 ]]; then
    init_log "Cleanup complete: $files_removed template files removed"
  fi
}

# cleanup_init_artifacts(keep_init)
# Remove .init-state.json and optionally init.sh
# keep_init="true" to skip script removal, anything else removes it
cleanup_init_artifacts() {
  local keep_init="${1:-false}"
  local files_removed=0
  
  if [[ -f .init-state.json ]]; then
    rm -f .init-state.json
    init_log "Removed .init-state.json"
    ((files_removed++))
  fi
  
  if [[ "$keep_init" != "true" ]]; then
    if [[ -f init.sh ]]; then
      rm -f init.sh
      init_log "Removed init.sh"
      ((files_removed++))
    fi
  fi
  
  if [[ $files_removed -gt 0 ]]; then
    init_log "Artifact cleanup complete: $files_removed files removed"
  fi
}

# detect_github_repo()
# Use gh repo view to auto-detect repo, print to stdout, return 0 on success, 1 on failure
detect_github_repo() {
  if ! command -v gh >/dev/null 2>&1; then
    init_error "gh CLI not found, cannot detect repository"
    return 1
  fi
  
  local repo
  if repo=$(gh repo view --json nameWithOwner -q . 2>/dev/null); then
    printf '%s' "$repo"
    return 0
  else
    init_error "Failed to detect GitHub repository"
    return 1
  fi
}

# show_summary(variables_json)
# Parse JSON and print a readable config summary to stderr
show_summary() {
  local variables_json="$1"
  
  if ! validate_json "$variables_json"; then
    init_error "Invalid JSON in show_summary"
    return 1
  fi
  
  init_log "=== Configuration Summary ==="
  
  if command -v jq >/dev/null 2>&1; then
    printf '%s\n' "$variables_json" | jq -r 'to_entries[] | "  \(.key): \(.value)"' >&2
  else
    # Fallback: basic parsing (assumes simple key-value JSON)
    printf '%s\n' "$variables_json" | grep -oE '"[^"]+":"[^"]*"' | \
      sed 's/"//g' | sed 's/:/ = /' | sed 's/^/  /' >&2
  fi
  
  init_log "=== End of Summary ==="
  return 0
}

# Export all functions for use in scripts that source this file
export -f init_log
export -f init_error
export -f init_warn
export -f prompt_user
export -f prompt_required
export -f validate_json
export -f save_checkpoint
export -f load_checkpoint
export -f checkpoint_exists
export -f cleanup_template_files
export -f cleanup_init_artifacts
export -f detect_github_repo
export -f show_summary

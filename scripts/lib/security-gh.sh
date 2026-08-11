#!/usr/bin/env bash
set -euo pipefail

repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set like owner/repo}"
owner="${repo%%/*}"
name="${repo##*/}"
dry_run="${DRY_RUN:-0}"

log() {
  printf '%s\n' "$1"
}

require_env() {
  local var_name="$1"
  : "${!var_name:?${var_name} must be set}"
}

require_dir() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    log "error: directory not found: ${dir}" >&2
    exit 1
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'missing command: %s\n' "$1" >&2
    exit 1
  }
}

repo_path() {
  local path="$1"
  if [[ -n "$path" ]]; then
    printf 'repos/%s/%s/%s' "$owner" "$name" "$path"
  else
    printf 'repos/%s/%s' "$owner" "$name"
  fi
}

gh_get_json() {
  gh api "$(repo_path "$1")"
}

gh_mutate_json() {
  local method="$1"
  local path="$2"
  log "${method} $(repo_path "$path")"
  if [[ "$dry_run" == "1" ]]; then
    cat >/dev/null
    return 0
  fi
  gh api -X "$method" "$(repo_path "$path")" --input -
}

gh_put_json() {
  gh_mutate_json PUT "$1"
}

gh_post_json() {
  gh_mutate_json POST "$1"
}

gh_patch_json() {
  gh_mutate_json PATCH "$1"
}

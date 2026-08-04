#!/usr/bin/env bash
set -euo pipefail

repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
owner="${repo%%/*}"
name="${repo##*/}"
default_branch="$(gh api "repos/${owner}/${name}" --jq '.default_branch')"
dry_run="${DRY_RUN:-0}"
merged_grace_days=7
unmerged_age_days=90
protected_branch_re="^(main|develop|release/)"

urlencode() {
  python - <<'PY' "$1"
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

epoch_from_iso() {
  python - <<'PY' "$1"
import datetime
import sys

value = sys.argv[1].replace("Z", "+00:00")
dt = datetime.datetime.fromisoformat(value)
print(int(dt.timestamp()))
PY
}

now_epoch() {
  python - <<'PY'
import time

print(int(time.time()))
PY
}

log() {
  printf '%s\n' "$1"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '%s\n' "$1" >> "$GITHUB_STEP_SUMMARY"
  fi
}

branch_names() {
  gh api "repos/${owner}/${name}/branches?per_page=100" --paginate --jq '.[].name'
}

branch_sha() {
  local branch="$1"
  gh api "repos/${owner}/${name}/git/ref/heads/$(urlencode "$branch")" --jq '.object.sha'
}

commit_date() {
  local sha="$1"
  gh api "repos/${owner}/${name}/commits/${sha}" --jq '.commit.committer.date // .commit.author.date'
}

commit_author_login() {
  local sha="$1"
  gh api "repos/${owner}/${name}/commits/${sha}" --jq '.author.login // empty'
}

merged_pr_date() {
  local branch="$1"
  gh api "repos/${owner}/${name}/pulls?state=closed&head=${owner}:${branch}&per_page=100" --jq '[.[] | select(.merged_at != null)] | sort_by(.merged_at) | last | .merged_at // empty'
}

delete_branch() {
  local branch="$1"
  local encoded_branch
  encoded_branch="$(urlencode "$branch")"
  log "delete branch=${branch}"
  if [[ "$dry_run" == "1" ]]; then
    return 0
  fi
  gh api -X DELETE "repos/${owner}/${name}/git/refs/heads/${encoded_branch}"
}

open_confirmation_issue() {
  local branch="$1"
  local sha="$2"
  local author="$3"
  local last_commit_date
  last_commit_date="$(commit_date "$sha")"
  local title="[branch-prune] Confirm deletion of ${branch}"
  local body
  body=$(cat <<EOF
This branch has been inactive for more than ${unmerged_age_days} days.

Branch: ${branch}
Last commit: ${last_commit_date}
Head commit: ${sha}

Please confirm whether this branch should be deleted.
EOF
)
  log "open confirmation issue branch=${branch} author=${author:-unassigned}"
  if [[ "$dry_run" == "1" ]]; then
    return 0
  fi
  if [[ -n "$author" ]]; then
    gh issue create --repo "$repo" --title "$title" --body "$body" --assignee "$author"
  else
    gh issue create --repo "$repo" --title "$title" --body "$body"
  fi
}

main() {
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    if [[ "$branch" == "$default_branch" || "$branch" =~ $protected_branch_re ]]; then
      log "skip protected branch=${branch}"
      continue
    fi

    sha="$(branch_sha "$branch")"
    merged_at="$(merged_pr_date "$branch")"

    if [[ -n "$merged_at" ]]; then
      merged_epoch="$(epoch_from_iso "$merged_at")"
      now_epoch="$(now_epoch)"
      if (( now_epoch - merged_epoch >= merged_grace_days * 86400 )); then
        delete_branch "$branch"
      else
        log "retain merged branch=${branch} merged_at=${merged_at}"
      fi
      continue
    fi

    commit_at="$(commit_date "$sha")"
    commit_epoch="$(epoch_from_iso "$commit_at")"
    now_epoch="$(now_epoch)"
    if (( now_epoch - commit_epoch >= unmerged_age_days * 86400 )); then
      author="$(commit_author_login "$sha")"
      open_confirmation_issue "$branch" "$sha" "$author"
    else
      log "retain active branch=${branch} last_commit=${commit_at}"
    fi
  done < <(branch_names)
}

main "$@"

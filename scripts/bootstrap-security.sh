#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/security-gh.sh
source "${script_dir}/lib/security-gh.sh"

require_command gh
require_command python
require_env RELEASE_TEAM_SLUG
require_env PRODUCTION_REVIEWERS
require_env PRODUCTION_WAIT_TIMER_MINUTES
require_env REQUIRED_CHECKS

required_checks_json="$(
  python -c '
import json
import sys

checks = [item.strip() for item in sys.argv[1].split(",") if item.strip()]
print(json.dumps([{"context": item} for item in checks]))
' "$REQUIRED_CHECKS"
)"

production_reviewers_json="$(
  python -c '
import json
import sys

print(json.dumps(json.loads(sys.argv[1])))
' "$PRODUCTION_REVIEWERS"
)"

apply_repo_settings() {
  log "apply repository settings"
  gh_patch_json "" <<'JSON'
{
  "has_wiki": false,
  "has_projects": false,
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": true,
  "delete_branch_on_merge": true,
  "allow_forking": false
}
JSON
}

enable_security_features() {
  log "enable vulnerability alerts and security features"
  gh_put_json "vulnerability-alerts" <<< '{}'
  gh_put_json "automated-security-fixes" <<< '{}'
  gh_patch_json "" <<'JSON'
{
  "security_and_analysis": {
    "advanced_security": { "status": "enabled" },
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
JSON
}

main_ruleset() {
  cat <<JSON
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"]
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" },
    { "type": "required_signatures" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 2,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": ${required_checks_json}
      }
    }
  ]
}
JSON
}

all_branches_ruleset() {
  cat <<'JSON'
{
  "name": "all-branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/*"]
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_signatures" }
  ]
}
JSON
}

tag_ruleset() {
  cat <<JSON
{
  "name": "tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/*"]
    }
  },
  "bypass_actors": [
    {
      "actor_type": "Team",
      "slug": "${RELEASE_TEAM_SLUG}",
      "bypass_mode": "always"
    }
  ],
  "rules": [
    { "type": "deletion" },
    { "type": "required_signatures" }
  ]
}
JSON
}

upsert_ruleset() {
  local ruleset_name="$1"
  local body="$2"
  local existing_id
  existing_id="$(
    gh_get_json "rulesets" | python -c '
import json
import sys

target = sys.argv[1]
data = json.load(sys.stdin)
for item in data:
    if item.get("name") == target:
        print(item["id"])
        raise SystemExit(0)
raise SystemExit(0)
' "$ruleset_name"
  )"
  if [[ -n "${existing_id:-}" ]]; then
    log "update ruleset ${ruleset_name}"
    gh_patch_json "rulesets/${existing_id}" <<< "$body"
  else
    log "create ruleset ${ruleset_name}"
    gh_post_json "rulesets" <<< "$body"
  fi
}

configure_environment() {
  log "configure production environment"
  gh_put_json "environments/production" <<JSON
{
  "wait_timer": ${PRODUCTION_WAIT_TIMER_MINUTES},
  "reviewers": ${production_reviewers_json}
}
JSON
}

main() {
  apply_repo_settings
  enable_security_features
  upsert_ruleset "main" "$(main_ruleset)"
  upsert_ruleset "all-branches" "$(all_branches_ruleset)"
  upsert_ruleset "tags" "$(tag_ruleset)"
  configure_environment
}

main "$@"

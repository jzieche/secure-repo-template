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

failures=0

expect_bool() {
  local label="$1"
  local actual="$2"
  local expected="$3"
  if [[ "$actual" != "$expected" ]]; then
    printf 'drift: %s expected=%s actual=%s\n' "$label" "$expected" "$actual" >&2
    failures=$((failures + 1))
  else
    printf 'ok: %s=%s\n' "$label" "$actual"
  fi
}

expect_string() {
  local label="$1"
  local actual="$2"
  local expected="$3"
  if [[ "$actual" != "$expected" ]]; then
    printf 'drift: %s expected=%s actual=%s\n' "$label" "$expected" "$actual" >&2
    failures=$((failures + 1))
  else
    printf 'ok: %s=%s\n' "$label" "$actual"
  fi
}

json_field() {
  local json="$1"
  local expr="$2"
  printf '%s' "$json" | python -c '
import json
import sys

expr = sys.argv[1]
data = json.load(sys.stdin)
for part in expr.split("."):
    if isinstance(data, list):
        data = data[int(part)]
    else:
        data = data[part]
print(data)
' "$expr"
}

repo_json="$(gh_get_json "")"
expect_bool "repo.has_wiki" "$(json_field "$repo_json" has_wiki)" "False"
expect_bool "repo.has_projects" "$(json_field "$repo_json" has_projects)" "False"
expect_bool "repo.allow_merge_commit" "$(json_field "$repo_json" allow_merge_commit)" "False"
expect_bool "repo.delete_branch_on_merge" "$(json_field "$repo_json" delete_branch_on_merge)" "True"
expect_bool "repo.allow_forking" "$(json_field "$repo_json" allow_forking)" "False"

expect_string "repo.secret_scanning" "$(json_field "$repo_json" security_and_analysis.secret_scanning.status)" "enabled"
expect_string "repo.secret_scanning_push_protection" "$(json_field "$repo_json" security_and_analysis.secret_scanning_push_protection.status)" "enabled"

rulesets_json="$(gh_get_json "rulesets")"
for expected_name in main all-branches tags; do
  if ! printf '%s' "$rulesets_json" | python -c '
import json
import sys

target = sys.argv[1]
data = json.load(sys.stdin)
for item in data:
    if item.get("name") == target:
        raise SystemExit(0)
raise SystemExit(1)
' "$expected_name"; then
    printf 'drift: missing ruleset=%s\n' "$expected_name" >&2
    failures=$((failures + 1))
  else
    printf 'ok: ruleset=%s\n' "$expected_name"
  fi
done

main_ruleset="$(printf '%s' "$rulesets_json" | python -c '
import json
import sys

data = json.load(sys.stdin)
for item in data:
    if item.get("name") == "main":
        print(json.dumps(item, sort_keys=True))
        raise SystemExit(0)
raise SystemExit(1)
')"

expect_string "main.target" "$(json_field "$main_ruleset" target)" "branch"
expect_string "main.ref_name.include.0" "$(json_field "$main_ruleset" conditions.ref_name.include.0)" "refs/heads/main"

main_ruleset_checks="$(printf '%s' "$main_ruleset" | python -c '
import json
import sys

data = json.load(sys.stdin)
for rule in data.get("rules", []):
    if rule.get("type") == "required_status_checks":
        print(json.dumps(rule, sort_keys=True))
        raise SystemExit(0)
raise SystemExit(1)
')"

expect_string "main.status_check.0" "$(json_field "$main_ruleset_checks" parameters.required_status_checks.0.context)" "CodeQL"
expect_string "main.status_check.1" "$(json_field "$main_ruleset_checks" parameters.required_status_checks.1.context)" "Dependency Review"

production_json="$(gh_get_json "environments/production")"
expect_string "production.wait_timer" "$(json_field "$production_json" wait_timer)" "${PRODUCTION_WAIT_TIMER_MINUTES}"
expect_string "production.reviewers.0.slug" "$(json_field "$production_json" reviewers.0.slug)" "$(printf '%s' "$PRODUCTION_REVIEWERS" | python -c 'import json,sys; print(json.loads(sys.stdin.read())[0]["slug"])')"

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi

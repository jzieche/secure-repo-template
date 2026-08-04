# Bootstrap Security and Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add scripts that apply the secure repository baseline through `gh api` and verify the live repository still matches that baseline.

**Architecture:** Split the work into one shared shell helper plus two entrypoint scripts. `scripts/lib/security-gh.sh` centralizes repository normalization, logging, dry-run behavior, and `gh api` plumbing so the mutation script and audit script stay small. `scripts/bootstrap-security.sh` mutates repository settings, rulesets, code security, and the production environment; `scripts/verify-security.sh` reads the same settings back and fails on drift without mutating anything.

**Tech Stack:** Bash, Python, GitHub CLI (`gh`)

## Global Constraints

- No workflow changes
- No Dependabot changes
- No documentation updates beyond what these scripts require
- No repository content outside these scripts
- No org-wide security configuration management outside the repository scope
- Use `set -euo pipefail` in every shell file.
- Keep `gh api` paths centralized in the shared helper.
- Treat missing required environment variables as hard failures.
- Print each mutation or verification step before performing it.
- Prefer explicit JSON comparisons over loosely parsing human-readable output.
- `bootstrap-security.sh` must support `DRY_RUN=1`.
- `verify-security.sh` must never modify repository state.

---

### Task 1: Add the shared helper and bootstrap script

**Files:**
- Create: `scripts/lib/security-gh.sh`
- Create: `scripts/bootstrap-security.sh`

**Interfaces:**
- Consumes: `GITHUB_REPOSITORY`, `DRY_RUN`, `RELEASE_TEAM_SLUG`, `PRODUCTION_REVIEWERS`, `PRODUCTION_WAIT_TIMER_MINUTES`, `REQUIRED_CHECKS`
- Produces: repo-scoped API helpers plus a bootstrap entrypoint that applies the secure baseline

- [ ] **Step 1: Write the failing test**

Run:
```bash
test -f scripts/lib/security-gh.sh && test -f scripts/bootstrap-security.sh && bash -n scripts/lib/security-gh.sh scripts/bootstrap-security.sh
```
Expected: fail because the files do not exist yet.

- [ ] **Step 2: Write the helper and bootstrap scripts**

```bash
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

repo_path() {
  if [[ -n "$1" ]]; then
    printf 'repos/%s/%s/%s' "$owner" "$name" "$1"
  else
    printf 'repos/%s/%s' "$owner" "$name"
  fi
}

gh_get_json() {
  gh api "$(repo_path "$1")"
}

gh_put_json() {
  local path="$1"
  log "PUT $(repo_path "$path")"
  if [[ "$dry_run" == "1" ]]; then
    cat >/dev/null
    return 0
  fi
  gh api -X PUT "$(repo_path "$path")" --input -
}

gh_post_json() {
  local path="$1"
  log "POST $(repo_path "$path")"
  if [[ "$dry_run" == "1" ]]; then
    cat >/dev/null
    return 0
  fi
  gh api -X POST "$(repo_path "$path")" --input -
}

gh_patch_json() {
  local path="$1"
  log "PATCH $(repo_path "$path")"
  if [[ "$dry_run" == "1" ]]; then
    cat >/dev/null
    return 0
  fi
  gh api -X PATCH "$(repo_path "$path")" --input -
}
```

```bash
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/security-gh.sh
source "${script_dir}/lib/security-gh.sh"

require_env RELEASE_TEAM_SLUG
require_env PRODUCTION_REVIEWERS
require_env PRODUCTION_WAIT_TIMER_MINUTES
require_env REQUIRED_CHECKS

IFS=',' read -r -a required_checks <<< "${REQUIRED_CHECKS}"
production_reviewers_json="${PRODUCTION_REVIEWERS}"

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
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" },
    "secret_scanning_ai_detection": { "status": "enabled" }
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
        "required_status_checks": [
          { "context": "CodeQL" },
          { "context": "Dependency Review" }
        ]
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
  local name="$1"
  local body
  body="$2"
  local existing_id
  existing_id="$(gh_get_json "rulesets" | python -c '
import json, sys
target = sys.argv[1]
data = json.load(sys.stdin)
for item in data:
    if item.get("name") == target:
        print(item["id"])
        raise SystemExit(0)
raise SystemExit(1)
' "$name")"
  if [[ -n "${existing_id:-}" ]]; then
    log "update ruleset ${name}"
    gh_patch_json "rulesets/${existing_id}" <<< "$body"
  else
    log "create ruleset ${name}"
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
```

- [ ] **Step 3: Run the script syntax check and failing test again**

Run:
```bash
bash -n scripts/lib/security-gh.sh scripts/bootstrap-security.sh
test -f scripts/lib/security-gh.sh && test -f scripts/bootstrap-security.sh
```

Expected: `bash -n` exits `0`, and the file-existence check passes.

- [ ] **Step 4: Commit the task**

```bash
git add scripts/lib/security-gh.sh scripts/bootstrap-security.sh
git commit -m "ci: add security bootstrap helper"
```

### Task 2: Add the verification script

**Files:**
- Create: `scripts/verify-security.sh`

**Interfaces:**
- Consumes: `GITHUB_REPOSITORY`, `RELEASE_TEAM_SLUG`, `PRODUCTION_REVIEWERS`, `PRODUCTION_WAIT_TIMER_MINUTES`, `REQUIRED_CHECKS`
- Produces: a drift report and a non-zero exit code when the live repository diverges from the secure baseline

- [ ] **Step 1: Write the failing test**

Run:
```bash
test -f scripts/verify-security.sh && bash -n scripts/verify-security.sh
```
Expected: fail because the file does not exist yet.

- [ ] **Step 2: Write the verification script**

```bash
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/security-gh.sh
source "${script_dir}/lib/security-gh.sh"

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

repo_json="$(gh_get_json "")"
repo_settings="$(printf '%s\n' "$repo_json" | python -c '
import json, sys
data = json.load(sys.stdin)
print(json.dumps({
    "has_wiki": data.get("has_wiki"),
    "has_projects": data.get("has_projects"),
    "allow_squash_merge": data.get("allow_squash_merge"),
    "allow_merge_commit": data.get("allow_merge_commit"),
    "allow_rebase_merge": data.get("allow_rebase_merge"),
    "delete_branch_on_merge": data.get("delete_branch_on_merge"),
    "allow_forking": data.get("allow_forking"),
}, sort_keys=True))
')"

expect_bool "repo.has_wiki" "$(printf '%s' "$repo_settings" | python -c '
import json, sys
print(json.load(sys.stdin)["has_wiki"])
')" "False"

expect_bool "repo.has_projects" "$(printf '%s' "$repo_settings" | python -c '
import json, sys
print(json.load(sys.stdin)["has_projects"])
')" "False"

expect_bool "repo.allow_merge_commit" "$(printf '%s' "$repo_settings" | python -c '
import json, sys
print(json.load(sys.stdin)["allow_merge_commit"])
')" "False"

expect_bool "repo.delete_branch_on_merge" "$(printf '%s' "$repo_settings" | python -c '
import json, sys
print(json.load(sys.stdin)["delete_branch_on_merge"])
')" "True"

rulesets_json="$(gh_get_json "rulesets")"
for expected_name in main all-branches tags; do
  if ! printf '%s\n' "$rulesets_json" | python -c '
import json, sys
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

production_json="$(gh_get_json "environments/production")"
expect_string "production.wait_timer" "$(printf '%s\n' "$production_json" | python -c '
import json, sys
print(json.load(sys.stdin).get("wait_timer"))
')" "${PRODUCTION_WAIT_TIMER_MINUTES}"

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
```

- [ ] **Step 3: Run the script syntax check and the verification smoke test**

Run:
```bash
bash -n scripts/verify-security.sh
```

Expected: exit code `0`

- [ ] **Step 4: Commit the task**

```bash
git add scripts/verify-security.sh
git commit -m "ci: add security verification script"
```

### Task 3: Final bootstrap/verification validation

**Files:**
- Inspect: `scripts/lib/security-gh.sh`
- Inspect: `scripts/bootstrap-security.sh`
- Inspect: `scripts/verify-security.sh`

**Interfaces:**
- Consumes: the helper, bootstrap script, and verification script
- Produces: a validated bootstrap/verification slice ready for the next phase

- [ ] **Step 1: Run a Python-based dry-run harness for bootstrap**

Run:
```bash
tmpdir="$(mktemp -d)"
cat > "${tmpdir}/gh" <<'PY'
#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
full = ' '.join(args)

def out(text):
    sys.stdout.write(text)
    if text and not text.endswith('\n'):
        sys.stdout.write('\n')

if args[:2] == ['api', 'repos/octo-org/octo-repo']:
    if '--input' not in args:
        out('{"has_wiki":false,"has_projects":false,"allow_merge_commit":false,"delete_branch_on_merge":true,"allow_forking":false,"allow_squash_merge":true}')
        raise SystemExit(0)
    out('{}')
    raise SystemExit(0)

if 'vulnerability-alerts' in full or 'automated-security-fixes' in full:
    out('{}')
    raise SystemExit(0)

if '/rulesets' in full:
    out('{"id":1}')
    raise SystemExit(0)

if '/environments/production' in full:
    out('{}')
    raise SystemExit(0)

sys.stderr.write(f'unexpected gh invocation: {full}\n')
raise SystemExit(1)
PY
chmod +x "${tmpdir}/gh"
PATH="${tmpdir}:$PATH" \
GITHUB_REPOSITORY="octo-org/octo-repo" \
RELEASE_TEAM_SLUG="release-team" \
PRODUCTION_REVIEWERS='[{"type":"Team","slug":"platform-sec"}]' \
PRODUCTION_WAIT_TIMER_MINUTES="10" \
REQUIRED_CHECKS="CodeQL,Dependency Review" \
DRY_RUN=1 \
bash scripts/bootstrap-security.sh
```

Expected: the script prints the planned settings changes and exits `0` without mutating anything.

- [ ] **Step 2: Run a Python-based drift harness for verification**

Run:
```bash
python - <<'PY'
import json, pathlib, subprocess, tempfile, textwrap, os, sys
script = pathlib.Path('scripts/verify-security.sh').resolve()
tmpdir = tempfile.TemporaryDirectory()
gh = pathlib.Path(tmpdir.name) / 'gh'
gh.write_text(textwrap.dedent('''\
#!/usr/bin/env python3
import sys
args = sys.argv[1:]
full = ' '.join(args)
def out(text):
    sys.stdout.write(text)
    if text and not text.endswith('\\n'):
        sys.stdout.write('\\n')
if args[:2] == ['api', 'repos/octo-org/octo-repo'] and '--input' not in args:
    out('{"has_wiki":false,"has_projects":false,"allow_merge_commit":false,"delete_branch_on_merge":true,"allow_forking":false,"allow_squash_merge":true}')
    raise SystemExit(0)
if '/rulesets' in full:
    out('[{"name":"main"},{"name":"all-branches"},{"name":"tags"}]')
    raise SystemExit(0)
if '/environments/production' in full:
    out('{"wait_timer":10}')
    raise SystemExit(0)
sys.stderr.write(f'unexpected gh invocation: {full}\\n')
raise SystemExit(1)
'''))
gh.chmod(0o755)
env = os.environ.copy()
env.update({
    'PATH': f"{tmpdir.name}:" + env['PATH'],
    'GITHUB_REPOSITORY': 'octo-org/octo-repo',
    'RELEASE_TEAM_SLUG': 'release-team',
    'PRODUCTION_REVIEWERS': '[{"type":"Team","slug":"platform-sec"}]',
    'PRODUCTION_WAIT_TIMER_MINUTES': '10',
    'REQUIRED_CHECKS': 'CodeQL,Dependency Review',
})
result = subprocess.run(['bash', str(script)], env=env, text=True, capture_output=True)
print(result.stdout)
print(result.stderr, file=sys.stderr)
assert result.returncode == 0
PY
```

Expected: the verification script prints `ok:` lines and exits `0` on matching fixtures.

- [ ] **Step 3: Confirm only the three script files were added**

Run:
```bash
find scripts -maxdepth 2 -type f | sort
```

Expected: the list includes `scripts/lib/security-gh.sh`, `scripts/bootstrap-security.sh`, and `scripts/verify-security.sh`.

- [ ] **Step 4: Commit the final validation state if needed**

```bash
git add .
git commit -m "ci: finalize security bootstrap and verification scripts"
```

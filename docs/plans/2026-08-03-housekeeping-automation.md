# Housekeeping Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the repository’s scheduled housekeeping automation for stale PR/issue cleanup and branch pruning.

**Architecture:** Split the work into two scheduled workflows with one shared shell helper. `stale.yml` owns policy enforcement for inactive issues and pull requests. `prune-branches.yml` delegates branch selection and deletion rules to `scripts/prune-branches.sh`, which keeps the operational logic testable and prevents the workflow from turning into a long inline shell script. Both workflows use the same baseline hardening rules: pinned actions, minimal permissions, bounded runtime, and concurrency control.

**Tech Stack:** GitHub Actions, Bash, GitHub CLI, YAML, `actions/stale`

## Global Constraints

- The repository starts empty, so file creation must be self-contained.
- Content should be template-friendly and not assume an existing org structure beyond a security owner.
- The license choice is fixed to MIT.
- No security scanning workflows in this slice.
- No bootstrap scripts or verification scripts in this slice.
- No Dependabot changes in this slice.
- No repository settings or rulesets in this slice.
- Both workflows use pinned third-party actions.
- Both workflows use explicit, minimal `permissions`.
- Both workflows use scheduled execution only.

---

### Task 1: Add the stale-item workflow

**Files:**
- Create: `.github/workflows/stale.yml`

**Interfaces:**
- Consumes: repository issues and pull requests with activity timestamps and labels
- Produces: stale labels, closure comments, and closed stale issues/PRs

- [ ] **Step 1: Write the workflow file**

```yaml
name: Stale

on:
  schedule:
    - cron: "0 4 * * 1"

permissions:
  issues: write
  pull-requests: write

jobs:
  stale:
    name: Mark stale items
    runs-on: ubuntu-latest
    timeout-minutes: 20
    concurrency:
      group: stale-${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true

    steps:
      - name: Close stale issues and pull requests
        uses: actions/stale@4391f3da665fdf50b6810c1a66712fb9ba21aa93
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          days-before-stale: 60
          days-before-issue-stale: 60
          days-before-pr-stale: 30
          days-before-close: 7
          days-before-issue-close: 14
          days-before-pr-close: 7
          stale-issue-label: stale
          stale-pr-label: stale
          exempt-issue-labels: security,pinned,keep-open
          exempt-pr-labels: security,pinned,keep-open
          stale-issue-message: >
            This issue has been automatically marked stale because it has had no
            recent activity. If it is still relevant, add a comment or remove
            the `stale` label to keep it open.
          stale-pr-message: >
            This pull request has been automatically marked stale because it has
            had no recent activity. If it is still relevant, add a comment or
            remove the `stale` label to keep it open.
          close-issue-message: >
            This issue is being closed because it has remained stale for 14 days.
            Reopen it and add a comment if you want to continue the discussion.
          close-pr-message: >
            This pull request is being closed because it has remained stale for
            7 days. Reopen it and add a comment if you want to continue.
          close-issue-reason: not_planned
          delete-branch: false
```

- [ ] **Step 2: Verify the workflow file**

Run:
```bash
test -f .github/workflows/stale.yml && grep -q "actions/stale@" .github/workflows/stale.yml && grep -q "days-before-issue-stale: 60" .github/workflows/stale.yml && grep -q "days-before-pr-stale: 30" .github/workflows/stale.yml && grep -q "exempt-issue-labels: security,pinned,keep-open" .github/workflows/stale.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add .github/workflows/stale.yml
git commit -m "ci: add stale item workflow"
```

### Task 2: Add the branch pruning helper script

**Files:**
- Create: `scripts/prune-branches.sh`

**Interfaces:**
- Consumes: `GITHUB_REPOSITORY`, `GITHUB_TOKEN`, and optional `DRY_RUN=1`
- Produces: branch deletion logs, confirmation issues for risky stale branches, and deletion requests for safe merged branches

- [ ] **Step 1: Write the helper script**

```bash
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
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
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
      merged_epoch="$(date -u -d "$merged_at" +%s)"
      now_epoch="$(date -u +%s)"
      if (( now_epoch - merged_epoch >= merged_grace_days * 86400 )); then
        delete_branch "$branch"
      else
        log "retain merged branch=${branch} merged_at=${merged_at}"
      fi
      continue
    fi

    commit_at="$(commit_date "$sha")"
    commit_epoch="$(date -u -d "$commit_at" +%s)"
    now_epoch="$(date -u +%s)"
    if (( now_epoch - commit_epoch >= unmerged_age_days * 86400 )); then
      author="$(commit_author_login "$sha")"
      open_confirmation_issue "$branch" "$sha" "$author"
    else
      log "retain active branch=${branch} last_commit=${commit_at}"
    fi
  done < <(branch_names)
}

main "$@"
```

- [ ] **Step 2: Verify the script**

Run:
```bash
bash -n scripts/prune-branches.sh
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add scripts/prune-branches.sh
git commit -m "ci: add branch pruning helper script"
```

### Task 3: Add the branch pruning workflow

**Files:**
- Create: `.github/workflows/prune-branches.yml`

**Interfaces:**
- Consumes: the helper script and repository branch metadata
- Produces: branch deletions for safe merged branches and confirmation issues for risky unmerged branches

- [ ] **Step 1: Write the workflow file**

```yaml
name: Prune Branches

on:
  schedule:
    - cron: "15 4 * * 1"

permissions:
  contents: write
  issues: write
  pull-requests: read

jobs:
  prune:
    name: Prune old branches
    runs-on: ubuntu-latest
    timeout-minutes: 30
    concurrency:
      group: prune-branches-${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true

    steps:
      - name: Checkout repository
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Prune branches
        shell: bash
        env:
          GITHUB_REPOSITORY: ${{ github.repository }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: bash scripts/prune-branches.sh
```

- [ ] **Step 2: Verify the workflow file**

Run:
```bash
test -f .github/workflows/prune-branches.yml && grep -q "contents: write" .github/workflows/prune-branches.yml && grep -q "issues: write" .github/workflows/prune-branches.yml && grep -q "scripts/prune-branches.sh" .github/workflows/prune-branches.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add .github/workflows/prune-branches.yml
git commit -m "ci: add branch pruning workflow"
```

### Task 4: Final housekeeping validation

**Files:**
- Inspect: `.github/workflows/stale.yml`
- Inspect: `.github/workflows/prune-branches.yml`
- Inspect: `scripts/prune-branches.sh`

**Interfaces:**
- Consumes: the stale workflow, pruning workflow, and helper script
- Produces: a validated housekeeping slice ready for the next phase

- [ ] **Step 1: Validate YAML and shell syntax**

Run:
```bash
python - <<'PY'
import pathlib, yaml
for path in [
    pathlib.Path('.github/workflows/stale.yml'),
    pathlib.Path('.github/workflows/prune-branches.yml'),
]:
    yaml.load(path.read_text(), Loader=yaml.BaseLoader)
    print(f"OK {path.name}")
PY
bash -n scripts/prune-branches.sh
```

Expected: both YAML files parse successfully and `bash -n` exits `0`.

- [ ] **Step 2: Exercise the pruning script in dry-run mode**

Run:
```bash
tmpdir="$(mktemp -d)"
cat > "${tmpdir}/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  api\ repos/*/*)
    if [[ "$*" == *"/branches?per_page=100"* ]]; then
      cat <<'JSON'
[{"name":"feature/old-merged"},{"name":"feature/stale-unmerged"},{"name":"main"},{"name":"develop"},{"name":"release/1.2"}]
JSON
      exit 0
    fi
    if [[ "$*" == *"/git/ref/heads/feature%2Fold-merged"* ]]; then
      echo '{"object":{"sha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}'
      exit 0
    fi
    if [[ "$*" == *"/git/ref/heads/feature%2Fstale-unmerged"* ]]; then
      echo '{"object":{"sha":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}}'
      exit 0
    fi
    if [[ "$*" == *"/commits/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"* ]]; then
      echo '{"commit":{"committer":{"date":"2026-07-01T00:00:00Z"}},"author":{"login":"octocat"}}'
      exit 0
    fi
    if [[ "$*" == *"/commits/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"* ]]; then
      echo '{"commit":{"committer":{"date":"2026-01-01T00:00:00Z"}},"author":{"login":"octocat"}}'
      exit 0
    fi
    if [[ "$*" == *"/pulls?state=closed&head=octo-org:feature/old-merged"* ]]; then
      cat <<'JSON'
[{"merged_at":"2026-07-20T00:00:00Z"}]
JSON
      exit 0
    fi
    if [[ "$*" == *"/pulls?state=closed&head=octo-org:feature/stale-unmerged"* ]]; then
      cat <<'JSON'
[]
JSON
      exit 0
    fi
    if [[ "$*" == *"/repos/octo-org/octo-repo"* ]]; then
      echo '{"default_branch":"main"}'
      exit 0
    fi
    ;;
  issue\ create*)
    echo "issue created"
    exit 0
    ;;
esac
echo "unexpected gh invocation: $*" >&2
exit 1
EOF
chmod +x "${tmpdir}/gh"
PATH="${tmpdir}:$PATH" GITHUB_REPOSITORY="octo-org/octo-repo" DRY_RUN=1 bash scripts/prune-branches.sh
```

Expected: the script logs planned deletions and confirmations without mutating the repository.

- [ ] **Step 3: Commit the final validation state if needed**

```bash
git add .
git commit -m "ci: finalize housekeeping automation"
```

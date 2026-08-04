# Housekeeping Automation Implementation Plan

## Goal
Add the repository’s scheduled housekeeping automation for stale PR/issue cleanup and branch pruning.

## Scope
This slice implements only the two housekeeping workflows and one shared helper script:

- `.github/workflows/stale.yml`
- `.github/workflows/prune-branches.yml`
- `scripts/prune-branches.sh`

## Non-goals
- No security scanning workflows
- No bootstrap scripts or verification scripts
- No Dependabot changes
- No repository settings or rulesets
- No additional documentation beyond what the workflow and script files require

## Design summary
This slice is split into two independent scheduled workflows because they have different failure modes and different responsibilities:

- `stale.yml` is a policy-enforcement workflow that labels and closes inactive PRs and issues.
- `prune-branches.yml` is an operational cleanup workflow that identifies old branches, deletes only the safe ones, and asks for confirmation before deleting risky unmerged branches.

The branch-pruning logic lives in `scripts/prune-branches.sh` so the workflow stays small and the branch selection/deletion rules are easier to test and review.

## File-by-file design

### `.github/workflows/stale.yml`
Run weekly on a schedule. Use `actions/stale` pinned to a full commit SHA. Configure separate inactivity windows for PRs and issues:

- PRs: label as `stale` after 30 days, close after 7 more days
- issues: label as `stale` after 60 days, close after 14 more days

Exclude items with the labels `security`, `pinned`, or `keep-open`. Post a comment that explains the closure policy and how to reopen the item.

### `.github/workflows/prune-branches.yml`
Run weekly on a schedule. Use the GitHub CLI to call the shared pruning script. The workflow should:

- list merged branches
- skip `main`, `develop`, and release branches
- delete merged branches older than 7 days
- find unmerged branches with no commits in 90 days
- open an issue tagging the branch author before deleting risky unmerged branches
- log deletions for auditability

### `scripts/prune-branches.sh`
Implement the branch-selection logic in a shell script that uses `gh api` for repository and branch queries. Keep the script focused on:

- determining which branches are safe to delete immediately
- identifying stale unmerged branches that require confirmation
- printing or logging each action before it happens

The script should fail loudly on API or deletion errors rather than swallowing them.

## Shared conventions
Both workflows should follow the same hardening baseline used by the security scan workflows:

- pin third-party actions to full commit SHAs
- set minimal `permissions`
- use `concurrency` to avoid overlapping scheduled runs
- keep shell logic isolated in the script rather than embedding complex inline command chains in the workflow

## Error handling and reporting
- `stale.yml` should make it obvious in its comment why an item was closed and how to reopen it.
- `prune-branches.sh` should log every branch deletion and every branch that is deferred for confirmation.
- If `gh api` fails, the pruning workflow should fail instead of continuing with partial data.

## Testing strategy
Verify the slice using file-level and script-level checks:

- parse the workflow YAML
- confirm the stale workflow triggers, labels, and close windows match the policy
- confirm the pruning workflow calls the helper script and uses scheduled execution
- run the pruning script in a dry-run-oriented test harness if the implementation adds one; otherwise validate the script content and shell syntax directly

## Acceptance criteria
- `stale.yml` exists and enforces the stale-label/close policy described above.
- `prune-branches.yml` exists and delegates branch selection to `scripts/prune-branches.sh`.
- The pruning script exists and implements the branch deletion and confirmation workflow described above.
- The slice stays limited to housekeeping automation only.

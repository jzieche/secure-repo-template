# Bootstrap Security and Verification Implementation Plan

## Goal
Add scripts that apply the secure repository baseline through `gh api` and verify the live repository still matches that baseline.

## Scope
This slice implements the bootstrap and verification scripts plus one shared helper:

- `scripts/lib/security-gh.sh`
- `scripts/bootstrap-security.sh`
- `scripts/verify-security.sh`

## Non-goals
- No workflow changes
- No Dependabot changes
- No documentation updates beyond what these scripts require
- No repository content outside these scripts
- No org-wide security configuration management outside the repository scope

## Design summary
The bootstrap and verification scripts share a small helper layer so they normalize repository identity, shell flags, and `gh api` access the same way. `bootstrap-security.sh` applies the secure baseline: repository settings, rulesets, code security, and the production environment. `verify-security.sh` reads the live repository settings back through `gh api`, compares them against the same baseline, and exits non-zero on any drift.

The scripts are intentionally separate because they have different failure modes: bootstrap mutates state, while verification only reports drift.

## File-by-file design

### `scripts/lib/security-gh.sh`
Provide shared shell helpers for:
- resolving and validating `GITHUB_REPOSITORY`
- building repo-scoped API paths
- handling `DRY_RUN=1`
- emitting consistent log lines
- performing simple JSON and string assertions from `gh api` output

This file should stay small and generic so both entrypoint scripts can source it without duplicating plumbing.

### `scripts/bootstrap-security.sh`
Accept the repository name through `GITHUB_REPOSITORY` and accept org-specific settings through environment variables or arguments:

- release team slug for tag creation restrictions
- production reviewers
- production wait timer
- required status check names

Apply the repository baseline through `gh api`:

- disable wiki and projects
- enable vulnerability alerts and automated security fixes
- enable private vulnerability reporting
- enable secret scanning and push protection
- disable merge commits
- enable delete-branch-on-merge
- disable forking
- create or update rulesets for `main`, all branches, and tags
- enable CodeQL and Dependabot security features where the repository supports them
- create the `production` environment with reviewers and a wait timer

Support `DRY_RUN=1` so callers can inspect what would change without mutating the repository.

### `scripts/verify-security.sh`
Read the live repository state via `gh api` and compare it to the secure baseline. Report drift for:

- repository settings
- rulesets
- code security settings
- production environment configuration

Exit non-zero if any required setting is missing or differs from the baseline. Support `DRY_RUN=1` only if it improves diagnostics without mutating state; the script must never modify the repository.

## Shared conventions
- Use `set -euo pipefail` in every shell file.
- Keep `gh api` paths centralized in the shared helper.
- Treat missing required environment variables as hard failures.
- Print each mutation or verification step before performing it.
- Prefer explicit JSON comparisons over loosely parsing human-readable output.

## Error handling and reporting
- Bootstrap should fail immediately if `gh api` returns an error for a required setting.
- Verification should print the specific setting or rule that drifted before exiting non-zero.
- Dry runs should still emit the same step-by-step log messages as real runs.

## Testing strategy
Verify the slice with lightweight checks:

- shell syntax checks for all three scripts
- file-level assertions that the bootstrap script references every required baseline control
- a dry-run harness for `bootstrap-security.sh` that stubs `gh api` and confirms the expected API calls are constructed
- a fixture-based drift test for `verify-security.sh` that feeds known-good and drifted `gh api` responses and checks exit codes

## Acceptance criteria
- The shared helper exists and is sourced by both entrypoint scripts.
- `bootstrap-security.sh` can apply the secure repository baseline and supports `DRY_RUN=1`.
- `verify-security.sh` detects drift and exits non-zero on mismatches.
- Both scripts rely on `gh api` and the same baseline assumptions.

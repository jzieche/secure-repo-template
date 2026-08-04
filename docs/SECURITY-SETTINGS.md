# Security Settings

This repository is designed to start new projects with a secure GitHub baseline.

## Repository settings

The bootstrap script applies these repository-level controls:

- wiki disabled
- projects disabled
- merge commits disabled
- delete branch on merge enabled
- forking disabled
- vulnerability alerts enabled
- automated security fixes enabled
- private vulnerability reporting enabled
- secret scanning enabled
- push protection enabled

## Rulesets

The bootstrap script creates or updates these rulesets:

### `main`

- applies to `refs/heads/main`
- requires signed commits
- requires linear history
- blocks force pushes and deletions
- requires two approving reviews
- requires CODEOWNERS review
- requires the `CodeQL` and `Dependency Review` status checks

### `all-branches`

- applies to every branch ref
- blocks force pushes and deletions
- requires signed commits

### `tags`

- applies to every tag ref
- restricts tag creation to the release team
- requires signed commits

## Code security

The template enables the repository’s code security features so the baseline can be enforced and audited from GitHub:

- CodeQL
- dependency review
- Scorecard
- zizmor

## Production environment

The bootstrap script creates a `production` environment with reviewers and a wait timer. This keeps production deployments gated by explicit approval.

## Verification

Run `scripts/verify-security.sh` after any security-sensitive change. The script checks the live repository settings, rulesets, and production environment and exits non-zero if the repository drifts from the baseline.

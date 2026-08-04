# Branch Naming

This repository uses branch names that are easy to read in review and safe for automation.

## Allowed branch families

- `main`
- `develop`
- `release/<major>.<minor>`
- `feature/<ticket>-<slug>`
- `bugfix/<ticket>-<slug>`
- `hotfix/<ticket>-<slug>`
- `chore/<ticket>-<slug>`

## Valid examples

- `main`
- `develop`
- `release/1.2`
- `feature/SEC-123-add-security-workflows`
- `bugfix/SEC-456-fix-branch-pruning`
- `hotfix/SEC-789-recover-bootstrap`
- `chore/SEC-321-refresh-docs`

## Invalid examples

- `wip`
- `my-branch`
- `release/v1`
- `feature/no-ticket`
- `feature/SEC-123`
- `bugfix/SEC-123_fix`

## Why this matters

Branch naming keeps reviews predictable, helps automation decide which branches are safe to prune, and makes it easier to spot work that belongs to the current secure template baseline.

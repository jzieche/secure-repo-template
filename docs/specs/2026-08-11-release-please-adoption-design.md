# Release Please Adoption Design

## Overview

This project adopts Release Please for this repository so releases are managed
through a release pull request workflow on `main`, with automated changelog and
GitHub Release publishing when that release PR is merged.

## Goals

- Adopt Release Please in this repository (not as template baseline content).
- Use a dedicated workflow file named `release.yml`.
- Create and maintain a root `CHANGELOG.md` automatically.
- Keep configuration explicit and easy to audit via committed config files.
- Follow existing repository workflow conventions for pinned actions, explicit
  permissions, and clear failure behavior.

## Non-goals

- Adding Release Please to scaffold outputs for downstream repositories.
- Reworking unrelated CI/security workflows.
- Introducing additional release tooling alongside Release Please.

## Current State

The repository has multiple security and maintenance workflows under
`.github/workflows/` and does not currently have a release automation workflow.
Release-related controls today focus on repository protection (for example, tag
rulesets), not automated release PR and changelog generation.

## Proposed Design

### 1) Release workflow

Add `.github/workflows/release.yml`:

- Trigger on pushes to `main` and manual `workflow_dispatch`.
- Use concurrency to prevent overlapping release runs on the same ref.
- Set least-privilege permissions needed for Release Please to open/update
  release PRs and create GitHub releases.
- Invoke `googleapis/release-please-action` with pinned action references and a
  config-file + manifest-file driven setup.

### 2) Repository release configuration

Add explicit Release Please config files:

- `.release-please-config.json` for strategy and behavior:
  - `release-type: simple`
  - root package/component settings for a single-repo release flow
  - `changelog-path: CHANGELOG.md`
- `.release-please-manifest.json` to track the root component version state.

This keeps the release model transparent and allows straightforward updates as
the repository evolves.

### 3) Data flow and behavior

1. Conventional commits merge into `main`.
2. Workflow runs Release Please.
3. Release Please creates or updates the release PR with version bump and
   changelog updates.
4. When the release PR is merged, Release Please creates a Git tag and a
   GitHub Release based on the release PR contents.
5. `CHANGELOG.md` remains the durable changelog source in-repo.

## Error Handling

- If Release Please cannot create/update a release PR (permissions, branch
  policies, or invalid config), the workflow fails and surfaces the action
  error in GitHub Actions logs.
- No silent fallbacks: release failures require explicit remediation.
- Existing workflows remain unchanged, reducing risk of coupled failures.

## Testing and Verification

Validation should use existing project tooling and GitHub Actions checks:

- Confirm workflow YAML shape matches repository conventions and passes
  workflow lint/audit checks already present in CI (for workflow changes).
- Merge at least one conventional-commit PR to `main` and verify Release Please
  opens/updates the release PR.
- After merging the release PR, verify:
  - GitHub Release is created
  - tag is created
  - `CHANGELOG.md` updates are included

## Migration Notes

- This is additive and low-risk: only new release automation files are added.
- No existing workflow behavior is replaced.
- If needed, release automation can be disabled by removing `release.yml`
  without affecting other baseline security workflows.

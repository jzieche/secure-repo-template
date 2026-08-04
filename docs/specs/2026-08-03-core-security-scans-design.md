# Core Security Scans Implementation Plan

## Goal
Add the repository’s primary security-scanning GitHub Actions workflows so pull requests and scheduled runs produce code scanning, dependency risk, supply-chain score, and workflow-security checks.

## Scope
This slice implements the four core security scan workflows only:

- `.github/workflows/codeql.yml`
- `.github/workflows/dependency-review.yml`
- `.github/workflows/scorecard.yml`
- `.github/workflows/zizmor.yml`

## Non-goals
- No secret-scan audit workflow
- No stale-issue or branch-pruning automation
- No bootstrap scripts or repository settings
- No Dependabot configuration changes
- No documentation updates beyond what these workflows require

## Design summary
Each workflow stays narrow and single-purpose, but they share a common hardening baseline: pinned third-party actions, explicit permissions, bounded execution time, and concurrency controls where appropriate. The four workflows complement each other:

- CodeQL handles static code analysis on repository code.
- dependency-review blocks unsafe dependency changes in pull requests.
- Scorecard measures supply-chain hygiene and publishes results to GitHub Security.
- zizmor audits workflow files themselves so the template demonstrates secure GitHub Actions patterns.

Keeping them separate avoids mixing triggers, permissions, and reporting paths while still giving the template a coherent security posture.

## Workflow architecture

### Shared conventions
All workflows should follow these rules:
- pin third-party actions to full commit SHAs
- set the smallest practical `permissions`
- define a reasonable `timeout-minutes`
- use `concurrency` where the workflow can be superseded by a newer run
- avoid shell interpolation of untrusted GitHub context inside `run:` blocks

These conventions are part of the template’s security story, not optional polish.

### `.github/workflows/codeql.yml`
Run on pull requests and pushes to the default branch. Use GitHub’s CodeQL action to auto-detect supported languages and upload SARIF results. Keep permissions minimal and ensure the workflow is available for PR feedback and default-branch coverage.

### `.github/workflows/dependency-review.yml`
Run on pull requests only. Fail the workflow when a dependency change introduces high/critical vulnerabilities or known malware. This workflow exists only to gate PRs, so it should not run on pushes or schedules.

### `.github/workflows/scorecard.yml`
Run on a weekly schedule and on pushes to the default branch. Upload Scorecard output to the Security tab so the template has an external supply-chain score signal. Keep the workflow simple and non-blocking unless the upload itself fails.

### `.github/workflows/zizmor.yml`
Run on pull requests that touch `.github/workflows/**`. Use `zizmorcore/zizmor` to statically analyze workflow files for:

- `unpinned-uses`
- `template-injection`
- `artipacked`
- `excessive-permissions`
- `ref-confusion`
- `dangerous-triggers`
- `self-hosted-runner`
- `known-vulnerable-actions`
- `github-env`
- `bot-conditions`

Use pedantic mode so the workflow catches all severities, and upload the report in a way that can be surfaced in GitHub Security.

## Error handling and reporting
- CodeQL and Scorecard should publish to the Security tab when possible so their results persist outside the CI log.
- dependency-review should fail fast with a clear job summary when a pull request introduces risky dependencies.
- zizmor should fail on any workflow-security finding at medium severity or above, because the template should model secure workflow practices.

## Testing strategy
Verify the workflows in the smallest way that proves each trigger and hardening choice:

- lint or parse the YAML files if the repo already has a supported workflow-linting command
- verify the file paths, triggers, and permissions in the committed workflow files
- use the repo’s workflow templates as the source of truth for SARIF upload and security-tab reporting

Because this slice is workflow-only, the implementation phase should focus on file-level verification and careful review of the YAML, not on trying to execute GitHub-hosted jobs locally.

## Acceptance criteria
- All four workflow files exist at the paths listed in Scope.
- Each workflow has a single clear responsibility.
- Third-party actions are pinned to full commit SHAs.
- Permissions are explicit and minimal.
- CodeQL, dependency-review, Scorecard, and zizmor triggers match the design above.
- Secret-scan audit remains out of scope for this slice.

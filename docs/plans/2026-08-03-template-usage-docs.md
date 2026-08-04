# Template Usage Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a clear usage guide so new consumers know how to use the template, authenticate with GitHub CLI, and set the environment variables for bootstrap and verification.

**Architecture:** Keep [README.md](/Users/jaredzieche/projects/secure-repo-template/README.md) as the landing page and add one dedicated usage guide for setup and environment variables. The README should stay concise and point to the detailed guide, while [docs/USING-THE-TEMPLATE.md](/Users/jaredzieche/projects/secure-repo-template/docs/USING-THE-TEMPLATE.md) carries the step-by-step runbook, copy-pasteable environment variable examples, and troubleshooting notes. Existing security and branch docs remain separate references so each topic stays small and maintainable.

**Tech Stack:** Markdown

## Global Constraints

- No workflow changes
- No script changes
- No repository settings changes
- No additional docs outside the files listed in Scope
- No changes to the existing security settings or branch naming docs
- Keep the README concise and action-oriented.
- Use plain markdown and short sections.
- Make the docs copy reusable by template consumers.
- Do not introduce new requirements that are not already enforced by the scripts or workflows.

---

### Task 1: Refresh the README landing page

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: the current template contents and the existing security scripts/docs already present in the repository
- Produces: the main landing page for new template consumers and contributors

- [ ] **Step 1: Write the failing test**

Run:
```bash
test -f README.md && grep -q "docs/USING-THE-TEMPLATE.md" README.md
```

Expected: fail because the README does not yet point readers to the usage guide.

- [ ] **Step 2: Write the updated README content**

```markdown
# GitHub Secure Repository Template

This repository is a security-first starter template.

It includes:

- a disclosure policy in [SECURITY.md](./SECURITY.md)
- branch naming guidance in [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md)
- security baseline details in [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md)
- GitHub Actions workflows for CodeQL, dependency review, Scorecard, and zizmor
- scheduled stale-item and branch-pruning automation
- bootstrap and verification scripts for the secure baseline

## Using this template

1. Create a repository from this template.
2. Authenticate with GitHub CLI before running the scripts:
   - `gh auth login`
   - `gh auth status`
3. Run `scripts/bootstrap-security.sh` with the repository-specific environment values for your organization.
4. Run `scripts/verify-security.sh` to confirm the repository matches the secure baseline.
5. Read [docs/USING-THE-TEMPLATE.md](./docs/USING-THE-TEMPLATE.md) for the full setup guide and environment-variable reference.

## Before you open a security-sensitive PR

- Review the checklist in `.github/PULL_REQUEST_TEMPLATE.md`
- Confirm the branch name matches [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md)
- Review the security baseline in [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md)

## What is already configured

- security policy files for disclosure and intake
- CodeQL, dependency review, Scorecard, and zizmor workflows
- stale-item cleanup and branch pruning workflows
- bootstrap and verification scripts for repository security settings
```

- [ ] **Step 3: Run the README check again**

Run:
```bash
test -f README.md && grep -q "docs/USING-THE-TEMPLATE.md" README.md && grep -q "gh auth login" README.md && grep -q "scripts/bootstrap-security.sh" README.md
```

Expected: exit code `0`

- [ ] **Step 4: Commit the README refresh**

```bash
git add README.md
git commit -m "docs: refresh README landing page"
```

### Task 2: Add the template usage guide

**Files:**
- Create: `docs/USING-THE-TEMPLATE.md`

**Interfaces:**
- Consumes: the bootstrap script, verification script, and the existing security/branch docs already in the repository
- Produces: the detailed runbook that explains prerequisites, auth, environment variables, examples, and troubleshooting

- [ ] **Step 1: Write the failing test**

Run:
```bash
test -f docs/USING-THE-TEMPLATE.md && grep -q "PRODUCTION_REVIEWERS" docs/USING-THE-TEMPLATE.md
```

Expected: fail because the usage guide does not exist yet.

- [ ] **Step 2: Write the usage guide**

```markdown
# Using This Template

This repository is meant to be used as a GitHub template for secure new projects.

## Prerequisites

- GitHub CLI (`gh`) installed
- authenticated GitHub CLI session (`gh auth login` and `gh auth status` both succeed)
- access to the repository created from this template

## One-time setup

Before running the bootstrap script, export the values that are specific to your organization:

```bash
export GITHUB_REPOSITORY="octo-org/octo-repo"
export RELEASE_TEAM_SLUG="release-team"
export PRODUCTION_WAIT_TIMER_MINUTES="10"
export REQUIRED_CHECKS="CodeQL,Dependency Review"
export PRODUCTION_REVIEWERS='[{"type":"Team","slug":"platform-sec"}]'
```

If you want to preview the bootstrap actions without changing the repository, set `DRY_RUN=1`.

## Bootstrapping the repository

Run:

```bash
scripts/bootstrap-security.sh
```

The script applies the repository security baseline, creates or updates the rulesets, and configures the production environment.

## Verifying the repository

Run:

```bash
scripts/verify-security.sh
```

The verification script compares the live repository to the secure baseline and exits non-zero if anything drifts.

## Environment variables

### Required for both scripts

- `GITHUB_REPOSITORY` — repository name in `owner/repo` form
- `RELEASE_TEAM_SLUG` — team slug allowed to bypass the tag ruleset
- `PRODUCTION_REVIEWERS` — JSON array of production environment reviewers
- `PRODUCTION_WAIT_TIMER_MINUTES` — wait timer for the production environment
- `REQUIRED_CHECKS` — comma-separated status checks required by the `main` ruleset

### Optional

- `DRY_RUN` — set to `1` to print the bootstrap actions without mutating the repository

## Troubleshooting

### `gh auth status` fails

Run `gh auth login` and sign in with an account that can administer the repository.

### `PRODUCTION_REVIEWERS` is invalid JSON

Use a valid JSON array such as:

```json
[{"type":"Team","slug":"platform-sec"}]
```

### The scripts report missing environment variables

Double-check the exported variable names above and confirm they are still present in the shell where you run the scripts.
```

- [ ] **Step 3: Run the usage-guide check**

Run:
```bash
test -f docs/USING-THE-TEMPLATE.md && grep -q "gh auth status" docs/USING-THE-TEMPLATE.md && grep -q "DRY_RUN" docs/USING-THE-TEMPLATE.md && grep -q "PRODUCTION_REVIEWERS" docs/USING-THE-TEMPLATE.md && grep -q "Troubleshooting" docs/USING-THE-TEMPLATE.md
```

Expected: exit code `0`

- [ ] **Step 4: Commit the usage guide**

```bash
git add docs/USING-THE-TEMPLATE.md
git commit -m "docs: add template usage guide"
```

### Task 3: Final documentation validation

**Files:**
- Inspect: [README.md](/Users/jaredzieche/projects/secure-repo-template/README.md)
- Inspect: [docs/USING-THE-TEMPLATE.md](/Users/jaredzieche/projects/secure-repo-template/docs/USING-THE-TEMPLATE.md)

**Interfaces:**
- Consumes: the refreshed README and the new usage guide
- Produces: a validated documentation set ready for the next phase

- [ ] **Step 1: Run the final content checks**

Run:
```bash
grep -q "bootstrap-security.sh" README.md && grep -q "verify-security.sh" README.md && grep -q "gh auth login" docs/USING-THE-TEMPLATE.md && grep -q "REQUIRED_CHECKS" docs/USING-THE-TEMPLATE.md
```

Expected: exit code `0`

- [ ] **Step 2: Confirm only the documented files changed**

Run:
```bash
find README.md docs -maxdepth 2 -type f | sort
```

Expected: the list includes the refreshed README and the new usage guide only.

- [ ] **Step 3: Commit the final validation state if needed**

```bash
git add README.md docs/USING-THE-TEMPLATE.md
git commit -m "docs: finalize template usage documentation"
```

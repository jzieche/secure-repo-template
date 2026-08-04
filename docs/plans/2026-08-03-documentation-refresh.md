# Documentation Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the repository documentation so the template clearly explains its security baseline, setup flow, and branch naming rules.

**Architecture:** Keep the documentation split by responsibility. `README.md` stays the entry point and short template landing page, while `docs/SECURITY-SETTINGS.md` explains the secure baseline and `docs/BRANCH-NAMING.md` documents the branch rules with examples. This keeps the README concise and lets each policy topic evolve independently without turning the landing page into a wall of text.

**Tech Stack:** Markdown

## Global Constraints

- No workflow changes
- No script changes
- No repository settings changes
- No additional docs outside the files listed in Scope
- No blog-style prose or long-form design notes
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

- [ ] **Step 1: Write the updated README content**

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

## Quick start

1. Create a repository from this template.
2. Run `scripts/bootstrap-security.sh` with the repository-specific environment values for your organization.
3. Run `scripts/verify-security.sh` to confirm the repository matches the secure baseline.
4. Use the branch naming rules before opening pull requests.

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

- [ ] **Step 2: Verify the README content**

Run:
```bash
test -f README.md && grep -q "bootstrap-security.sh" README.md && grep -q "verify-security.sh" README.md && grep -q "docs/SECURITY-SETTINGS.md" README.md && grep -q "docs/BRANCH-NAMING.md" README.md
```

Expected: exit code `0`

- [ ] **Step 3: Commit the README refresh**

```bash
git add README.md
git commit -m "docs: refresh README landing page"
```

### Task 2: Add the security settings and branch naming docs

**Files:**
- Create: `docs/SECURITY-SETTINGS.md`
- Create: `docs/BRANCH-NAMING.md`

**Interfaces:**
- Consumes: the bootstrap script, verification script, and branch-pruning workflow already in the repository
- Produces: the detailed docs pages that explain the secure baseline and branch rules

- [ ] **Step 1: Write the docs files**

```markdown
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
```

```markdown
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
```

- [ ] **Step 2: Verify the docs files**

Run:
```bash
test -f docs/SECURITY-SETTINGS.md && test -f docs/BRANCH-NAMING.md && grep -q "Repository settings" docs/SECURITY-SETTINGS.md && grep -q "main" docs/BRANCH-NAMING.md && grep -q "Invalid examples" docs/BRANCH-NAMING.md
```

Expected: exit code `0`

- [ ] **Step 3: Commit the docs pages**

```bash
git add docs/SECURITY-SETTINGS.md docs/BRANCH-NAMING.md
git commit -m "docs: add security settings and branch naming guides"
```

### Task 3: Final documentation validation

**Files:**
- Inspect: `README.md`
- Inspect: `docs/SECURITY-SETTINGS.md`
- Inspect: `docs/BRANCH-NAMING.md`

**Interfaces:**
- Consumes: the refreshed README and the two new docs pages
- Produces: a validated documentation set ready for the next phase

- [ ] **Step 1: Run the final content checks**

Run:
```bash
grep -q "bootstrap-security.sh" README.md && grep -q "verify-security.sh" README.md && grep -q "CodeQL" docs/SECURITY-SETTINGS.md && grep -q "Valid examples" docs/BRANCH-NAMING.md
```

Expected: exit code `0`

- [ ] **Step 2: Confirm only the documented files changed**

Run:
```bash
find README.md docs -maxdepth 2 -type f | sort
```

Expected: the list includes the refreshed README and the two docs pages only.

- [ ] **Step 3: Commit the final validation state if needed**

```bash
git add README.md docs/SECURITY-SETTINGS.md docs/BRANCH-NAMING.md
git commit -m "docs: finalize documentation refresh"
```

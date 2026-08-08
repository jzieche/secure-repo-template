# Copilot Instructions for secure-repo-template

This repo is a security-first GitHub repository template. It ships a bootstrap
script, security workflows, and a Gruntworks runbook (`RUNBOOK.mdx`) that
creates a new repo from this template, applies the baseline, lets the user
pick one scaffold (Helm or Terraform), and verifies the result.

## Layout

- [init.sh](../init.sh), [scripts/lib/init-utils.sh](../scripts/lib/init-utils.sh), [scripts/bootstrap-security.sh](../scripts/bootstrap-security.sh), [scripts/verify-security.sh](../scripts/verify-security.sh) — bootstrap/verify automation, tested by [test-init-utils.sh](../test-init-utils.sh).
- [scripts/runbook/](../scripts/runbook) — scripts invoked directly by `RUNBOOK.mdx` `<Command>` steps.
- [scaffolds/helm/](../scaffolds/helm) and [scaffolds/terraform-module/](../scaffolds/terraform-module) — Boilerplate (`boilerplate.yml`) templates rendered into the user's repo by the runbook's `<Template>` step. Only one scaffold is chosen per repo.
- [docs/plans/](../docs/plans) and [docs/specs/](../docs/specs) — the **canonical, committed** locations for implementation plans and design docs (including ones authored via Superpowers skills). Never write plans/specs elsewhere.
- `.github/workflows/` — CodeQL, dependency-review, Scorecard, zizmor, stale, and branch-pruning workflows that ship as part of the security baseline.

## Superpowers artifacts — do not commit

`.superpowers/` and `docs/superpowers/` are local Superpowers working directories and are git-ignored (see [.gitignore](../.gitignore)). When a Superpowers skill (e.g. `writing-plans`, `brainstorming`) produces a plan or design doc for this repo's own changes, put/move it directly into [docs/plans/](../docs/plans) or [docs/specs/](../docs/specs) — do not leave committed copies under `docs/superpowers/`. This mirrors past cleanup work (see `docs/plans/2026-08-07-superpowers-artifact-cleanup.md`).

## RUNBOOK.mdx conventions

- It's Gruntworks Runbook MDX, not plain Markdown — components like `<Inputs>`, `<Command>`, `<GitClone>`, `<Template>`, and `<Check>` have specific required attributes (`id`, `githubAuthId`, `inputsId`, `path`, `target`, `command`). Preserve exact block syntax and ordering when editing.
- YAML embedded in `<Inputs>` blocks must stay inside fenced code blocks (```yaml ... ```) — stripping the fences breaks rendering.
- Never bake vendor/tool branding into the runbook title or user-facing headings; keep titles generic (e.g. "Repository Creation Runbook").
- Each scaffold path backs up `README.md` before rendering the scaffold's `Template`, since scaffold templates may otherwise overwrite repo-specific README edits. Preserve this backup/restore pattern when touching scaffold sections.
- The runbook offers exactly one scaffold at a time (Helm or Terraform) — don't chain multiple `<Template>` renders into the same flow.

## Branch naming

Follow [docs/BRANCH-NAMING.md](../docs/BRANCH-NAMING.md) exactly: `feature/<TICKET>-<slug>`, `bugfix/...`, `hotfix/...`, `chore/...`, or `release/<major>.<minor>`. Branches without a ticket id (e.g. `feature/no-ticket`) are invalid and may be pruned by automation.

## Shell script conventions

- Scripts under `scripts/` use `set -u` (not `set -e`) so helper functions can return non-zero without killing the shell — follow this pattern rather than adding `set -e`.
- Logging helpers (`init_log`, `init_warn`, `init_error`) write to stderr with `[INIT]`/`[WARN]`/`[ERROR]` prefixes; reuse them instead of raw `echo`.
- [test-init-utils.sh](../test-init-utils.sh) is the existing test harness for `scripts/lib/init-utils.sh` — run it (`./test-init-utils.sh`) after changing that library rather than adding a new test framework.

## Documentation changes

- Plans and design specs go in `docs/plans/` and `docs/specs/` respectively, named `YYYY-MM-DD-<slug>.md` / `YYYY-MM-DD-<slug>-design.md`, matching existing files.
- Don't add new top-level docs pages beyond what a task requires; link from [README.md](../README.md) if user-facing.

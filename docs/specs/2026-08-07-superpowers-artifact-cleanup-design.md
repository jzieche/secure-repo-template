# Superpowers Artifact Cleanup Design

## Goal
Make the repository treat Superpowers-generated artifacts as local-only workflow output while preserving the useful planning and spec documents that should live in the repo's canonical documentation structure.

## Scope
This change covers only repository hygiene for Superpowers artifacts:

- ignore future Superpowers-generated directories
- move existing Superpowers plan documents into `docs/plans/`
- move existing Superpowers spec documents into `docs/specs/`
- remove the old `docs/superpowers/` directory if it becomes empty

## Non-goals
- No content rewrite of the moved plan or spec files
- No reorganization of existing files already under `docs/plans/` or `docs/specs/`
- No changes to runbook behavior, scripts, or scaffold templates
- No new documentation pages beyond the cleanup design and implementation plan artifacts required by the workflow

## Design summary
The repository already has canonical folders for plans and specs under `docs/plans/` and `docs/specs/`. Superpowers should not create a second long-lived documentation tree in the repo. The cleanup should therefore do two things:

1. treat Superpowers working directories as ignored local artifacts
2. consolidate any committed Superpowers plans/specs into the canonical docs structure

This keeps the repo layout simple, prevents churn from tool-generated directories, and preserves the useful authored documents in the locations the repo already uses.

## Current state
The repository currently contains:

- `.superpowers/`
- `docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md`
- `docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`

The repository also already uses:

- `docs/plans/`
- `docs/specs/`

## Proposed changes

### Ignore rules
Create or update the repository ignore file so these paths are ignored going forward:

- `.superpowers/`
- `docs/superpowers/`

If a root `.gitignore` file does not exist yet, create one with only the required entries for this change.

### Document relocation
Move the committed Superpowers documents into the canonical folders without renaming their filenames:

- `docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md` → `docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md`
- `docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md` → `docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`

This preserves history and avoids unnecessary content edits.

### Directory cleanup
After the moves, remove `docs/superpowers/` if it is empty. The ignore rule should remain so future tool output does not recreate a tracked documentation tree there.

## File-by-file design

### `.gitignore`
Add entries for `.superpowers/` and `docs/superpowers/`.

### `docs/plans/`
Receive the moved plan document from `docs/superpowers/plans/` with no content changes.

### `docs/specs/`
Receive the moved design document from `docs/superpowers/specs/` with no content changes.

### `docs/superpowers/`
Remove the directory if empty after file moves.

## Error handling and edge cases
- If the destination files already exist, stop and inspect before overwriting anything.
- If the source Superpowers files are missing, do not invent replacements; only move what exists.
- If `docs/superpowers/` is not empty after the move for any reason, leave only the remaining contents and do not force-delete unrelated files.

## Verification strategy
- Confirm `.gitignore` contains both ignore entries.
- Confirm the two documents exist in `docs/plans/` and `docs/specs/`.
- Confirm the source files no longer exist under `docs/superpowers/`.
- Confirm `git status --short` reflects only the intended move and ignore-file changes.

## Acceptance criteria
- Future `.superpowers/` and `docs/superpowers/` directories are ignored by git.
- The existing Superpowers plan file lives under `docs/plans/`.
- The existing Superpowers design file lives under `docs/specs/`.
- The old `docs/superpowers/` tree no longer contains the moved plan/spec files.
- The repository layout reflects a single canonical location for committed plans and specs.

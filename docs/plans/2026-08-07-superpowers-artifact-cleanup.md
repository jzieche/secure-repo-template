# Superpowers Artifact Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ignore Superpowers-generated working directories and move the existing committed Superpowers plan/spec documents into the repository's canonical docs folders.

**Architecture:** This change is pure repository hygiene. It creates or updates a root `.gitignore` for local-only Superpowers directories, moves the two committed Superpowers documents into `docs/plans/` and `docs/specs/`, and removes the old `docs/superpowers/` tree only if it becomes empty. The implementation avoids content edits to the moved documents and uses shell verification commands instead of code tests.

**Tech Stack:** Git, shell commands, Markdown, `.gitignore`

## Global Constraints

- No content rewrite of the moved plan or spec files
- No reorganization of existing files already under `docs/plans/` or `docs/specs/`
- No changes to runbook behavior, scripts, or scaffold templates
- No new documentation pages beyond the cleanup design and implementation plan artifacts required by the workflow
- Future `.superpowers/` and `docs/superpowers/` directories are ignored by git.
- The existing Superpowers plan file lives under `docs/plans/`.
- The existing Superpowers design file lives under `docs/specs/`.
- The old `docs/superpowers/` tree no longer contains the moved plan/spec files.
- The repository layout reflects a single canonical location for committed plans and specs.

---

### Task 1: Add ignore rules for Superpowers artifacts

**Files:**
- Create: `.gitignore` (if missing)
- Modify: `.gitignore`

**Interfaces:**
- Consumes: the current repository root and the requirement to ignore `.superpowers/` and `docs/superpowers/`
- Produces: a root `.gitignore` file containing exact ignore entries for `.superpowers/` and `docs/superpowers/`

- [ ] **Step 1: Inspect whether `.gitignore` already exists and what it contains**

Run:
```bash
test -f .gitignore && sed -n '1,120p' .gitignore || echo ".gitignore missing"
```

Expected: either the current `.gitignore` contents or the single line `.gitignore missing`

- [ ] **Step 2: Write the ignore file content**

Run:
```bash
if test -f .gitignore; then
  grep -Fx '.superpowers/' .gitignore >/dev/null || printf '\n.superpowers/\n' >> .gitignore
  grep -Fx 'docs/superpowers/' .gitignore >/dev/null || printf 'docs/superpowers/\n' >> .gitignore
else
  cat > .gitignore <<'EOF'
.superpowers/
docs/superpowers/
EOF
fi
```

Expected: `.gitignore` exists and contains both ignore lines exactly once or more

- [ ] **Step 3: Verify the ignore rules are present**

Run:
```bash
grep -Fx '.superpowers/' .gitignore && grep -Fx 'docs/superpowers/' .gitignore
```

Expected: both lines are printed and the command exits `0`

- [ ] **Step 4: Commit the ignore-rule update**

```bash
git add .gitignore
git commit -m "chore: ignore superpowers artifacts"
```

### Task 2: Move the committed Superpowers documents into canonical docs folders

**Files:**
- Modify: `docs/plans/`
- Modify: `docs/specs/`
- Remove: `docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md`
- Remove: `docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`

**Interfaces:**
- Consumes: `docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md` and `docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`
- Produces: `docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md` and `docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`

- [ ] **Step 1: Verify the source files exist and the destination files do not**

Run:
```bash
test -f docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md && \
  test -f docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md && \
  test ! -e docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md && \
  test ! -e docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md
```

Expected: exit code `0`

- [ ] **Step 2: Move the plan document into `docs/plans/`**

Run:
```bash
mv docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md \
  docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md
```

Expected: command exits `0` and the file now exists at `docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md`

- [ ] **Step 3: Move the design document into `docs/specs/`**

Run:
```bash
mv docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md \
  docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md
```

Expected: command exits `0` and the file now exists at `docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`

- [ ] **Step 4: Verify the files are present in the canonical folders**

Run:
```bash
test -f docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md && \
  test -f docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md && \
  test ! -e docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md && \
  test ! -e docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md
```

Expected: exit code `0`

- [ ] **Step 5: Commit the document moves**

```bash
git add docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md \
  docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md \
  docs/superpowers/plans/2026-08-06-gruntworks-runbook-boilerplate.md \
  docs/superpowers/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md
git commit -m "chore: relocate superpowers docs"
```

### Task 3: Remove the obsolete docs/superpowers tree if empty and verify the final layout

**Files:**
- Remove: `docs/superpowers/` (only if empty)
- Verify: `.gitignore`
- Verify: `docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md`
- Verify: `docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md`

**Interfaces:**
- Consumes: the moved documents from Task 2 and the ignore rules from Task 1
- Produces: a repo layout with no committed plan/spec files under `docs/superpowers/` and a final verified git diff

- [ ] **Step 1: Remove empty leftover directories under `docs/superpowers/`**

Run:
```bash
rmdir docs/superpowers/plans 2>/dev/null || true
rmdir docs/superpowers/specs 2>/dev/null || true
rmdir docs/superpowers 2>/dev/null || true
```

Expected: no error if the directories are already absent; if they were empty, they are removed

- [ ] **Step 2: Verify the old tree is gone or contains no moved plan/spec files**

Run:
```bash
test ! -e docs/superpowers || find docs/superpowers -maxdepth 2 -type f | cat
```

Expected: either exit code `0` with no output because `docs/superpowers` is gone, or a short listing that does not include the moved plan/spec files

- [ ] **Step 3: Verify the final repository state**

Run:
```bash
grep -Fx '.superpowers/' .gitignore && \
  grep -Fx 'docs/superpowers/' .gitignore && \
  test -f docs/plans/2026-08-06-gruntworks-runbook-boilerplate.md && \
  test -f docs/specs/2026-08-06-gruntworks-runbook-boilerplate-design.md && \
  git status --short
```

Expected: the two ignore lines are printed, both moved files exist, and `git status --short` shows only the intended `.gitignore` change, the two renames/moves, and the removal of the old `docs/superpowers/` tree

- [ ] **Step 4: Commit the directory cleanup if it changed tracked state**

Run:
```bash
if git status --short docs/superpowers | grep -q .; then
  git add -A docs/superpowers
  git commit -m "chore: remove obsolete superpowers docs tree"
else
  echo "No tracked docs/superpowers cleanup changes remain"
fi
```

Expected: either a cleanup commit is created, or the command prints `No tracked docs/superpowers cleanup changes remain`

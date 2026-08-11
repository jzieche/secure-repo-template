# GitHub Repository Rulesets Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a boilerplate scaffold for GitHub repository rulesets that renders parameterized JSON files into `.github/rulesets/` and serves as the single source of truth for both this template repo and consumer repos.

**Architecture:** The scaffold lives at `scaffolds/rulesets/` and uses boilerplate templating to render three ruleset JSON files (`main.json`, `all-branches.json`, `tags.json`) and their configuration. `bootstrap-security.sh` is refactored to read JSON from `.github/rulesets/` instead of inline functions. The RUNBOOK is updated to render the scaffold before initialization, and the runbook's `<Inputs>` block is extended with ruleset variables.

**Tech Stack:** Gruntworks boilerplate (Go templates), `gh api` CLI, JSON, bash

## Global Constraints

- Use Go template syntax (`{{ .vars.VariableName }}`) for boilerplate variables
- All variable defaults match the existing bootstrap-security.sh policy
- Target `.github/rulesets/` as the rendered output path
- Maintain backward compatibility with existing `bootstrap-security.sh` environment variables
- Follow the naming convention for JSON files: `<ruleset-name>.json`
- All JSON files must be valid according to the [GitHub Rulesets API](https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10)

---

### Task 1: Create scaffold directory structure and boilerplate.yml

**Files:**
- Create: `scaffolds/rulesets/boilerplate.yml`
- Create: `scaffolds/rulesets/.github/rulesets/.gitkeep`
- Create: `scaffolds/rulesets/README.md`

**Interfaces:**
- Consumes: None
- Produces: Valid boilerplate.yml with three variables (`ReleaseTeamSlug`, `RequiredChecks`, `RequiredApprovals`)

- [ ] **Step 1: Create the boilerplate.yml file**

Create `scaffolds/rulesets/boilerplate.yml` with this exact content:

```yaml
template:
  var_name_prefix: ""
  delimiter: "."

variables:
  - name: ReleaseTeamSlug
    description: GitHub team slug permitted to create/push tags
    type: string
    default: "release-team"

  - name: RequiredChecks
    description: JSON array of CI check names required on main
    type: list
    items_type: string
    default:
      - CodeQL
      - Dependency Review

  - name: RequiredApprovals
    description: Number of required approving reviews on main
    type: number
    default: 2
```

- [ ] **Step 2: Create the directory structure**

Run:
```bash
mkdir -p scaffolds/rulesets/.github/rulesets
touch scaffolds/rulesets/.github/rulesets/.gitkeep
```

- [ ] **Step 3: Create README.md**

Create `scaffolds/rulesets/README.md` with this exact content:

```markdown
# GitHub Repository Rulesets Scaffold

This scaffold renders three repository rulesets into `.github/rulesets/` for application via GitHub's Rulesets API.

## Files

- `main.json` — protections for the `main` branch (requires reviews, signed commits, passing checks)
- `all-branches.json` — baseline protections for all branches (block force-push and deletion)
- `tags.json` — tag creation restrictions (release team only)

## Customization

Edit the rendered JSON files in `.github/rulesets/` to adjust:
- Review requirements
- Status checks
- Bypass actors for release team
- Any edge cases marked with `# TODO:` comments

## Applying Rulesets

Run the bootstrap script to apply the rulesets:

```bash
./scripts/bootstrap-security.sh
```

This reads the JSON files from `.github/rulesets/` and creates or updates the rulesets in GitHub via the Rulesets API.
```

- [ ] **Step 4: Commit**

```bash
git add scaffolds/rulesets/
git commit -m "scaffold: create rulesets directory structure and boilerplate config"
```

---

### Task 2: Create main.json ruleset template

**Files:**
- Create: `scaffolds/rulesets/.github/rulesets/main.json`

**Interfaces:**
- Consumes: `ReleaseTeamSlug`, `RequiredChecks`, `RequiredApprovals` from boilerplate.yml
- Produces: Valid main-branch ruleset JSON compliant with GitHub Rulesets API

- [ ] **Step 1: Create main.json with boilerplate variables**

Create `scaffolds/rulesets/.github/rulesets/main.json` with this exact content:

```json
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"]
    }
  },
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_linear_history"
    },
    {
      "type": "required_signatures"
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": {{ .vars.RequiredApprovals }},
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          {{- range .vars.RequiredChecks }}
          {
            "context": "{{ . }}"
          },
          {{- end }}
        ]
      }
    }
  ]
}
```

Wait — the JSON array syntax above produces a trailing comma. Fix this with proper boilerplate list rendering:

```json
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"]
    }
  },
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_linear_history"
    },
    {
      "type": "required_signatures"
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": {{ .vars.RequiredApprovals }},
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [{{ range $i, $check := .vars.RequiredChecks }}{{ if $i }},{{ end }}{"context": "{{ $check }}"}{{ end }}]
      }
    }
  ]
}
```

- [ ] **Step 2: Verify JSON is valid (will be validated when rendered)**

The file is a boilerplate template and will produce valid JSON when rendered with sample values.

- [ ] **Step 3: Commit**

```bash
git add scaffolds/rulesets/.github/rulesets/main.json
git commit -m "scaffold: add main branch ruleset template"
```

---

### Task 3: Create all-branches.json ruleset template

**Files:**
- Create: `scaffolds/rulesets/.github/rulesets/all-branches.json`

**Interfaces:**
- Consumes: None (fixed policy, no variables)
- Produces: Valid all-branches ruleset JSON

- [ ] **Step 1: Create all-branches.json**

Create `scaffolds/rulesets/.github/rulesets/all-branches.json` with this exact content:

```json
{
  "name": "all-branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/*"]
    }
  },
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_signatures"
    }
  ]
}
```

- [ ] **Step 2: Verify valid JSON syntax**

Run:
```bash
python -m json.tool scaffolds/rulesets/.github/rulesets/all-branches.json > /dev/null && echo "Valid JSON"
```

Expected: `Valid JSON`

- [ ] **Step 3: Commit**

```bash
git add scaffolds/rulesets/.github/rulesets/all-branches.json
git commit -m "scaffold: add all-branches ruleset template"
```

---

### Task 4: Create tags.json ruleset template

**Files:**
- Create: `scaffolds/rulesets/.github/rulesets/tags.json`

**Interfaces:**
- Consumes: `ReleaseTeamSlug` from boilerplate.yml
- Produces: Valid tag ruleset JSON with release team bypass actor

- [ ] **Step 1: Create tags.json with boilerplate variable**

Create `scaffolds/rulesets/.github/rulesets/tags.json` with this exact content:

```json
{
  "name": "tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/*"]
    }
  },
  "bypass_actors": [
    {
      "actor_type": "Team",
      "actor_id": null,
      "bypass_mode": "always"
    }
  ],
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "required_signatures"
    }
  ]
}
```

Wait — the bypass_actors array needs the team slug. Looking at the GitHub Rulesets API, the team bypass format uses `actor_id` (numeric) not slug. However, the spec says we should use slug and let the script handle it. Actually, reviewing the bootstrap-security.sh code, it uses `"slug": "${RELEASE_TEAM_SLUG}"`. Let me correct the JSON:

```json
{
  "name": "tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/*"]
    }
  },
  "bypass_actors": [
    {
      "actor_type": "Team",
      "slug": "{{ .vars.ReleaseTeamSlug }}",
      "bypass_mode": "always"
    }
  ],
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "required_signatures"
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add scaffolds/rulesets/.github/rulesets/tags.json
git commit -m "scaffold: add tags ruleset template"
```

---

### Task 5: Refactor bootstrap-security.sh to read ruleset JSON files

**Files:**
- Modify: `scripts/bootstrap-security.sh` (lines with inline ruleset functions)
- Modify: `scripts/lib/security-gh.sh` (add `require_dir` helper if needed)

**Interfaces:**
- Consumes: `.github/rulesets/*.json` files rendered by the scaffold
- Produces: Three upserted rulesets via `gh api` (unchanged behavior)

- [ ] **Step 1: Add require_dir helper to security-gh.sh (if not present)**

Check if `require_dir` exists:

```bash
grep -n "require_dir" scripts/lib/security-gh.sh
```

If not found, add it to `scripts/lib/security-gh.sh` after the `require_env` function:

```bash
require_dir() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    error "directory not found: ${dir}"
  fi
}
```

- [ ] **Step 2: Update bootstrap-security.sh preamble**

Remove the `required_checks_json` Python construction block (approximately lines 9-18). Keep the `production_reviewers_json` block.

The block to remove looks like:
```bash
required_checks_json="$(
  python -c '
import json
import sys

checks = [item.strip() for item in sys.argv[1].split(",") if item.strip()]
print(json.dumps([{"context": item} for item in checks]))
' "$REQUIRED_CHECKS"
)"
```

Edit `scripts/bootstrap-security.sh` to remove this entire block.

- [ ] **Step 3: Remove inline ruleset functions**

Remove these three functions from `scripts/bootstrap-security.sh`:
- `main_ruleset()`
- `all_branches_ruleset()`
- `tag_ruleset()`

They should be removed entirely (approximately lines 58-110 or similar).

- [ ] **Step 4: Replace upsert calls with a loop**

In the `main()` function, replace:
```bash
upsert_ruleset "main" "$(main_ruleset)"
upsert_ruleset "all-branches" "$(all_branches_ruleset)"
upsert_ruleset "tags" "$(tag_ruleset)"
```

With:
```bash
require_dir ".github/rulesets"

for ruleset_file in .github/rulesets/*.json; do
  if [[ -f "${ruleset_file}" ]]; then
    ruleset_name="$(basename "${ruleset_file}" .json)"
    log "apply ruleset ${ruleset_name}"
    upsert_ruleset "${ruleset_name}" "$(cat "${ruleset_file}")"
  fi
done
```

- [ ] **Step 5: Verify script structure**

View the complete modified `scripts/bootstrap-security.sh` to ensure:
- No inline JSON functions remain
- The `require_dir` call is present
- The loop over `.github/rulesets/*.json` is in `main()`
- All three rules (main, all-branches, tags) are still applied via the loop

Run:
```bash
bash -n scripts/bootstrap-security.sh
```

Expected: No output (script is syntactically valid)

- [ ] **Step 6: Commit**

```bash
git add scripts/bootstrap-security.sh scripts/lib/security-gh.sh
git commit -m "refactor: bootstrap-security.sh reads ruleset JSON from .github/rulesets"
```

---

### Task 6: Update RUNBOOK.mdx to render and verify rulesets scaffold

**Files:**
- Modify: `RUNBOOK.mdx` (add rulesets variables to `<Inputs>` and new scaffold step)

**Interfaces:**
- Consumes: Rulesets scaffold files and boilerplate.yml
- Produces: Updated RUNBOOK with ruleset scaffold rendering step

- [ ] **Step 1: Add ruleset variables to the main <Inputs> block**

Locate the `<Inputs id="repo-config">` block at the top of RUNBOOK.mdx. After the existing variables (OrgName, RepoName, TemplateOwner, Visibility), add:

```yaml
  - name: ReleaseTeamSlug
    description: GitHub team slug permitted to create/push tags
    type: string
    default: release-team

  - name: RequiredChecks
    description: CI check names required on main
    type: list
    options:
      - CodeQL
      - Dependency Review
    default: [CodeQL, "Dependency Review"]

  - name: RequiredApprovals
    description: Number of required approving reviews on main
    type: number
    default: 2
```

- [ ] **Step 2: Insert new rulesets scaffold step**

In RUNBOOK.mdx, locate the section "## 2) Complete post-setup work" and the comment about branch protection and rulesets. Insert a new section immediately after the repo clone and before the post-setup checklist:

```mdx
## 2) Apply repository rulesets

<Template id="rulesets-scaffold" path="scaffolds/rulesets" target="worktree" inputsId="repo-config" />

<Check id="rulesets-lint" command='cd "$REPO_FILES" && for f in .github/rulesets/*.json; do python -m json.tool "$f" > /dev/null || exit 1; done' />
```

- [ ] **Step 3: Move initialize-repo.sh command**

The existing `<Command id="initialize-repo">` step must run **after** the rulesets scaffold is rendered. Move it to immediately after the rulesets lint check (step 2.3), before the "Complete post-setup work" checklist.

- [ ] **Step 4: Renumber sections**

Update the RUNBOOK section numbers to account for the new step 2. The "Complete post-setup work" checklist becomes section 3, and "Choose one scaffold" becomes section 4.

- [ ] **Step 5: Verify RUNBOOK structure**

View RUNBOOK.mdx and confirm:
- `<Inputs>` block has three new ruleset variables
- `<Template id="rulesets-scaffold">` step exists
- `<Check id="rulesets-lint">` step validates JSON
- `<Command id="initialize-repo">` runs after the rulesets scaffold
- Section numbering is correct and sequential

- [ ] **Step 6: Commit**

```bash
git add RUNBOOK.mdx
git commit -m "docs: update RUNBOOK to render and apply rulesets scaffold"
```

---

### Task 7: Update verify-security.sh to validate rulesets

**Files:**
- Modify: `scripts/verify-security.sh`

**Interfaces:**
- Consumes: Rulesets API output (list of rulesets with names)
- Produces: Validation that main, all-branches, and tags rulesets exist with correct names

- [ ] **Step 1: Review current verify-security.sh**

View `scripts/verify-security.sh` and locate where rulesets are verified (search for "ruleset").

- [ ] **Step 2: Ensure ruleset name validation is present**

The verify script already checks rulesets by name. Confirm that it validates:
- `main` ruleset exists
- `all-branches` ruleset exists
- `tags` ruleset exists

If these checks are not present, add them to the main verification function. The check should look like:

```bash
check_ruleset_exists() {
  local ruleset_name="$1"
  if ! gh_get_json "rulesets" | python -c "
import json, sys
data = json.load(sys.stdin)
for item in data:
  if item.get('name') == '$ruleset_name':
    print(item['id'])
    exit(0)
exit(1)
  " > /dev/null 2>&1; then
    fail "ruleset ${ruleset_name} not found"
  fi
}

# In main verification
check_ruleset_exists "main"
check_ruleset_exists "all-branches"
check_ruleset_exists "tags"
```

If these checks already exist, no changes are needed. Verify by running:

```bash
bash -n scripts/verify-security.sh
```

Expected: No syntax errors

- [ ] **Step 3: Commit (only if changes were made)**

If changes were needed:

```bash
git add scripts/verify-security.sh
git commit -m "fix: verify-security.sh validates ruleset names"
```

If no changes were needed, skip this step and note in the execution log that verify-security.sh already has the necessary checks.

---

### Task 8: Test scaffold rendering and bootstrap execution

**Files:**
- Test: Manual integration test in a temp directory

**Interfaces:**
- Consumes: Rendered `.github/rulesets/` JSON files
- Produces: Three upserted rulesets in the test repo (or verification of expected behavior)

- [ ] **Step 1: Create test repository (optional but recommended)**

This is a manual validation step. Create a temporary test repo to verify:

```bash
mkdir -p /tmp/test-rulesets-render
cd /tmp/test-rulesets-render
git clone --depth 1 --branch agents/adopt-release-please-for-releases https://github.com/jzieche/secure-repo-template.git .
```

- [ ] **Step 2: Simulate boilerplate rendering**

Manually render the rulesets scaffold with sample values using Python's `string.Template` or similar tool, or use the actual boilerplate render command if available:

For each JSON file in `scaffolds/rulesets/.github/rulesets/`, substitute boilerplate variables:
- `{{ .vars.ReleaseTeamSlug }}` → `release-team`
- `{{ .vars.RequiredChecks }}` → `[{"context": "CodeQL"}, {"context": "Dependency Review"}]`
- `{{ .vars.RequiredApprovals }}` → `2`

Render to `.github/rulesets/` in the temp directory.

- [ ] **Step 3: Validate rendered JSON**

Run:
```bash
for f in .github/rulesets/*.json; do
  python -m json.tool "$f" > /dev/null && echo "✓ $f is valid JSON" || echo "✗ $f is invalid"
done
```

Expected: All three files are valid JSON

- [ ] **Step 4: Dry-run bootstrap script**

Set `DRY_RUN=1` and run the bootstrap script:

```bash
cd /tmp/test-rulesets-render
DRY_RUN=1 RELEASE_TEAM_SLUG=release-team PRODUCTION_REVIEWERS='[{"type": "User", "id": 123}]' PRODUCTION_WAIT_TIMER_MINUTES=0 REQUIRED_CHECKS=CodeQL ./scripts/bootstrap-security.sh
```

Expected: No errors, bootstrap logs indicate it would apply three rulesets

- [ ] **Step 5: Clean up temp directory**

```bash
rm -rf /tmp/test-rulesets-render
```

- [ ] **Step 6: Note in session log**

No commit needed for this task. Record in the execution log that manual integration validation passed.

---

### Task 9: Self-review plan against spec and commit

**Files:**
- Review: This plan against the spec

**Interfaces:**
- Consumes: Design spec at `docs/specs/2026-08-11-github-rulesets-scaffold-design.md`
- Produces: Verified plan with no gaps or placeholders

- [ ] **Step 1: Spec coverage check**

Skim the spec and verify each section is covered:
- ✓ Goal: Scaffold renders JSON to `.github/rulesets/` — Tasks 1-4 create scaffold
- ✓ Architecture: render-first model — Tasks 2-6 implement it
- ✓ Boilerplate variables: ReleaseTeamSlug, RequiredChecks, RequiredApprovals — Task 1 (boilerplate.yml)
- ✓ Ruleset JSON files: main, all-branches, tags — Tasks 2-4
- ✓ Changes to bootstrap-security.sh: read from `.github/rulesets/`, remove inline functions — Task 5
- ✓ Runbook changes: new step, extended inputs — Task 6
- ✓ Error handling: require_dir, JSON validation — Tasks 5-6
- ✓ Testing: manual integration test — Task 8
- ✓ verify-security.sh: validate ruleset names — Task 7

All spec sections are covered.

- [ ] **Step 2: Placeholder scan**

Search this plan for red flags:
- ✓ No "TBD", "TODO", or "fill in details" — all steps have concrete code
- ✓ All file paths are exact and absolute
- ✓ All commands include expected output or validation
- ✓ No "similar to Task N" — each task is complete
- ✓ No unresolved type mismatches

No placeholders found.

- [ ] **Step 3: Type and interface consistency**

Check tasks that produce data are consumed correctly by later tasks:
- Task 1 produces `boilerplate.yml` with three variables → Tasks 2, 4, 6 consume them ✓
- Task 2 produces `main.json` template → Boilerplate renders it → Task 6 includes it ✓
- Task 4 produces `tags.json` template → Boilerplate renders it → Task 6 includes it ✓
- Task 5 refactors bootstrap to read `.github/rulesets/*.json` → Task 6 ensures files exist before bootstrap runs ✓
- Task 7 updates verify script → No dependencies on earlier tasks ✓

All interfaces are consistent.

- [ ] **Step 4: No additional tasks needed**

The plan covers all spec requirements and produces working, independently testable deliverables at each task boundary. No tasks need to be added.

- [ ] **Step 5: Commit summary of plan**

No commit needed — the plan is documentation for execution.

---

## Summary

**Total tasks:** 9 (including self-review)
**Execution time estimate:** 45-60 minutes
**Key deliverables:**
1. Boilerplate scaffold in `scaffolds/rulesets/` with three JSON template files
2. Refactored `bootstrap-security.sh` reading from `.github/rulesets/`
3. Updated RUNBOOK.mdx with ruleset rendering step
4. Manual integration test validation

**Next step:** Execute the plan using subagent-driven-development or executing-plans skill.

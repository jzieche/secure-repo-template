# GitHub Repository Rulesets Scaffold — Design

**Date:** 2026-08-11  
**Status:** Approved

## Goal

Add a boilerplate scaffold for GitHub repository rulesets that:

1. Renders parameterized ruleset JSON files into `.github/rulesets/` in any consumer repo via the Gruntworks runbook `<Template>` step
2. Serves as the single source of truth for this template repo's own rulesets — `bootstrap-security.sh` reads the rendered JSON files instead of using inline JSON functions
3. Is applied as a dedicated runbook step, distinct from the Helm/Terraform code scaffolds

## Architecture

### Render-first model

The boilerplate scaffold is rendered by the runbook *before* `initialize-repo.sh` runs. The `<Template>` step substitutes all boilerplate variables and writes static JSON files. `bootstrap-security.sh` then reads those static files — no runtime substitution is needed in the script.

```
Runbook <Template> step
  → renders scaffolds/rulesets/ into .github/rulesets/
  → static JSON files (main.json, all-branches.json, tags.json)

initialize-repo.sh
  → calls bootstrap-security.sh
  → bootstrap reads .github/rulesets/*.json
  → upserts each ruleset via gh api
```

### Scaffold file layout

```
scaffolds/rulesets/
  boilerplate.yml             # variable definitions and render config
  .github/
    rulesets/
      main.json               # boilerplate template: main-branch protections
      all-branches.json       # boilerplate template: all-branches protections
      tags.json               # boilerplate template: tag protections
  README.md                   # usage notes for consumers
```

The target path `.github/rulesets/` matches GitHub's native convention for storing ruleset definitions and makes them visible and reviewable in the repo.

## Boilerplate Variables

Defined in `boilerplate.yml`. All variables have sensible defaults; consumers override them via the runbook `<Inputs>` step.

| Variable | Description | Default |
|---|---|---|
| `ReleaseTeamSlug` | GitHub team slug permitted to create/push tags | `release-team` |
| `RequiredChecks` | Comma-separated CI check names required on `main` | `CodeQL,Dependency Review` |
| `RequiredApprovals` | Number of required approving reviews on `main` | `2` |

Edge cases not covered by variables (e.g. custom bypass actors, environment-gated rules) are marked with `# TODO:` comments in the rendered JSON files.

## Ruleset JSON Files

Each file follows the [GitHub Rulesets API shape](https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10#create-a-repository-ruleset):

```json
{
  "name": "<ruleset-name>",
  "target": "branch|tag",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": [...] } },
  "bypass_actors": [...],
  "rules": [...]
}
```

### `main.json`

- Target: `refs/heads/main`
- Rules: deletion blocked, force-push blocked, linear history required, signed commits required, PR required (`RequiredApprovals` reviews, stale reviews dismissed, CODEOWNERS review required), required status checks (`RequiredChecks`)
- Bypass actors: none by default

### `all-branches.json`

- Target: `refs/heads/*`
- Rules: deletion blocked, force-push blocked, signed commits required
- No variables — fixed policy

### `tags.json`

- Target: `refs/tags/*`
- Rules: deletion blocked, signed commits required
- Bypass actors: team `ReleaseTeamSlug` with `bypass_mode: always` (allows tag creation by the release team)

## Changes to `bootstrap-security.sh`

Remove the three inline JSON functions (`main_ruleset`, `all_branches_ruleset`, `tag_ruleset`) and the per-ruleset `upsert_ruleset` calls. Replace with:

```bash
require_dir ".github/rulesets"

for ruleset_file in .github/rulesets/*.json; do
  ruleset_name="$(basename "${ruleset_file}" .json)"
  upsert_ruleset "${ruleset_name}" "$(cat "${ruleset_file}")"
done
```

The script requires `.github/rulesets/` to exist. If it is absent the script logs an error and exits non-zero. This invariant is satisfied because the runbook renders the scaffold before calling `initialize-repo.sh`.

The `required_checks_json` and `production_reviewers_json` construction via Python is removed from the bootstrap script preamble — those values are now baked into the rendered JSON by boilerplate.

## Runbook Changes

A new step is inserted between "Complete post-setup work" and "Choose one scaffold":

```mdx
## 2.5) Apply repository rulesets

<Template id="rulesets-scaffold" path="scaffolds/rulesets" target="worktree" inputsId="repo-config" />

<Command id="apply-rulesets" githubAuthId="gh-auth" path="scripts/runbook/initialize-repo.sh" />
```

Wait — `initialize-repo.sh` currently also calls `./init.sh` (which runs `bootstrap-security.sh`). The ordering must ensure `.github/rulesets/` is rendered before `initialize-repo.sh` runs. The new `<Template>` step satisfies this.

The `<Inputs>` block at the top of the runbook is extended with the three ruleset boilerplate variables (`ReleaseTeamSlug`, `RequiredChecks`, `RequiredApprovals`) so they are available to the `<Template>` step.

## Error Handling

- If `.github/rulesets/` is missing, `bootstrap-security.sh` logs `[ERROR] .github/rulesets/ not found — run the rulesets scaffold first` and exits 1
- If a ruleset file contains invalid JSON, `gh api` returns an error; the script surfaces it via the existing `upsert_ruleset` error path
- `verify-security.sh` is updated to validate that the three expected rulesets exist and have the correct names (it currently checks rulesets by name already)

## Testing

- Existing `./test-init-utils.sh` harness is not directly applicable here (it tests `scripts/lib/init-utils.sh`)
- The rendered JSON files should be validated with `python -m json.tool` or `jq` as a `<Check>` step in the runbook — add a `<Check id="rulesets-lint">` after the `<Template>` step
- Manual integration test: render scaffold into a test repo, run `bootstrap-security.sh`, verify three rulesets are created via `gh api repos/{owner}/{repo}/rulesets`

## Non-goals

- No org-level ruleset management (repo-level only)
- No dynamic ruleset modification after initial bootstrap
- No removal of rulesets that are no longer in `.github/rulesets/` (create/update only)
- No changes to the Helm or Terraform scaffolds

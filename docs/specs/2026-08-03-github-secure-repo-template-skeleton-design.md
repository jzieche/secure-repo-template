# GitHub Secure Repository Template — Repository Skeleton & Policy Files

## Goal
Create the initial template repository content that establishes a secure baseline before any workflows or automation are added.

## Scope
This slice implements only the repository skeleton and policy files from Phase 1 of the plan:

- `README.md`
- `LICENSE` (MIT)
- `.gitattributes`
- `SECURITY.md`
- `.github/CODEOWNERS`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/security-bug-report.yml`

## Non-goals
- No GitHub Actions workflows
- No Dependabot configuration
- No bootstrap or verification scripts
- No rulesets, repository settings, or GitHub API automation
- No additional docs beyond what is needed for these files

## File-by-file design

### `README.md`
Provide a short template overview that explains:
- this repository is a security-first starter template
- what the initial files are for
- that later phases will add automation and policy enforcement

Keep the README concise so it works as a template landing page without pretending the repository is feature-complete.

### `LICENSE`
Use the MIT License, as requested.

### `.gitattributes`
Enforce:
- LF line endings for text files
- binary file detection where appropriate

This should prevent line-ending churn across platforms while staying simple.

### `SECURITY.md`
Document the vulnerability disclosure process, including:
- a security contact path
- what information to include in reports
- expected response timing
- supported-version guidance for template consumers

The wording should be usable as-is in a new repository created from the template.

### `.github/CODEOWNERS`
Route sensitive areas to the security team or designated owners:
- `.github/`
- `scripts/`
- security-sensitive docs and policy files

The intent is to ensure changes to governance and automation get deliberate review.

### `.github/PULL_REQUEST_TEMPLATE.md`
Add a short checklist that asks contributors to confirm:
- security impact was considered
- tests or validation were run when relevant
- risky workflow or permission changes were reviewed carefully

Keep it brief so it is likely to be used.

### `.github/ISSUE_TEMPLATE/security-bug-report.yml`
Provide a structured security report form with fields for:
- summary
- affected component
- reproduction steps
- impact
- optional proof-of-concept or supporting context

The form should guide reporters toward actionable submissions without overcomplicating the intake flow.

## Constraints
- The repository starts empty, so file creation must be self-contained.
- Content should be template-friendly and not assume an existing org structure beyond a security owner.
- The license choice is fixed to MIT.

## Acceptance criteria
- All seven files exist at the paths above.
- The content matches the intended security-template purpose.
- No workflow or automation files are introduced yet.
- The repository remains focused on the first-phase skeleton only.

## Implementation notes
- Keep text concise and reusable across future template consumers.
- Prefer plain markdown and minimal YAML structure so the files are easy to customize later.

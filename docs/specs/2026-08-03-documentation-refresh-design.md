# Documentation Refresh Implementation Plan

## Goal
Refresh the repository documentation so the template clearly explains its security baseline, setup flow, and branch naming rules.

## Scope
This slice implements the documentation refresh only:

- `README.md`
- `docs/SECURITY-SETTINGS.md`
- `docs/BRANCH-NAMING.md`

## Non-goals
- No workflow changes
- No script changes
- No repository settings changes
- No additional docs outside the files listed in Scope
- No blog-style prose or long-form design notes

## Design summary
This slice keeps the documentation split by responsibility:

- `README.md` remains the entry point and template landing page.
- `docs/SECURITY-SETTINGS.md` explains the secure baseline and why each control exists.
- `docs/BRANCH-NAMING.md` documents the allowed branch patterns and examples.

That split keeps the README short enough to be useful while moving detailed policy and examples into dedicated docs pages.

## File-by-file design

### `README.md`
Update the README to act as the main template landing page. It should explain:

- that the repository is a security-first starter template
- which security controls are already present
- how to run the bootstrap and verification scripts
- where to find the security settings and branch naming docs
- what contributors should do before opening a security-sensitive PR

The README should stay concise, but it should include enough information for a new consumer to orient themselves without reading every doc page first.

### `docs/SECURITY-SETTINGS.md`
Document the security baseline and the rationale for each control:

- repository settings
- rulesets
- code security features
- production environment settings

Include a short explanation of how the bootstrap and verification scripts enforce this baseline and how teams can customize it safely.

### `docs/BRANCH-NAMING.md`
Document the branch naming policy used by the template:

- allowed branch families
- concrete examples of valid branch names
- concrete examples of invalid branch names
- a brief explanation of why the naming rules matter for review and automation

Keep the examples aligned with the branch policy enforced elsewhere in the template so the docs and scripts do not drift apart.

## Shared conventions
- Keep the README concise and action-oriented.
- Use plain markdown and short sections.
- Make the docs copy reusable by template consumers.
- Do not introduce new requirements that are not already enforced by the scripts or workflows.

## Error handling and reporting
- The README should point readers to the exact docs page for deeper detail rather than duplicating long explanations.
- The docs pages should avoid ambiguous wording about what is required versus what is guidance.

## Testing strategy
Verify the refresh with lightweight checks:

- confirm the README mentions the bootstrap and verification scripts
- confirm the security settings doc mentions repository settings, rulesets, code security, and the production environment
- confirm the branch naming doc includes both valid and invalid examples

## Acceptance criteria
- The README reflects the current security template behavior.
- `docs/SECURITY-SETTINGS.md` explains the baseline and its rationale.
- `docs/BRANCH-NAMING.md` documents the branch naming rules with examples.
- The docs stay aligned with the scripts and workflows already in the repository.

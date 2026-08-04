# Template Usage Docs Implementation Plan

## Goal
Add a clear usage guide so new consumers know how to use the template, authenticate with GitHub CLI, and set the environment variables for bootstrap and verification.

## Scope
This slice implements the usage documentation refresh only:

- `README.md`
- `docs/USING-THE-TEMPLATE.md`

## Non-goals
- No workflow changes
- No script changes
- No repository settings changes
- No additional docs outside the files listed in Scope
- No changes to the existing security settings or branch naming docs

## Design summary
This slice keeps the README as the landing page and adds one dedicated usage guide for setup and environment variables. The README points readers to the usage guide, while `docs/USING-THE-TEMPLATE.md` gives the detailed runbook with prerequisites, environment variables, examples, and troubleshooting.

## File-by-file design

### `README.md`
Add a short “Using this template” section that explains:

- the repository is intended to be used as a template
- the user should authenticate with `gh` before running scripts
- the bootstrap script requires environment variables for release-team and production settings
- the verification script uses the same environment variables to compare the live repo to the secure baseline
- the full setup details live in `docs/USING-THE-TEMPLATE.md`

Keep the README concise; its job is to orient the reader and link out, not duplicate the full runbook.

### `docs/USING-THE-TEMPLATE.md`
Document the end-to-end setup flow:

- prerequisites for using the template
- how to authenticate with GitHub CLI
- how to run `scripts/bootstrap-security.sh`
- how to run `scripts/verify-security.sh`
- which environment variables each script requires
- an example export block with copy-pasteable values
- a troubleshooting section for missing env vars, invalid JSON in `PRODUCTION_REVIEWERS`, and `gh` authentication failures

## Environment variable coverage
Document both repository-specific and auth/setup variables:

- `GITHUB_REPOSITORY`
- `DRY_RUN`
- `RELEASE_TEAM_SLUG`
- `PRODUCTION_REVIEWERS`
- `PRODUCTION_WAIT_TIMER_MINUTES`
- `REQUIRED_CHECKS`
- GitHub CLI authentication state (`gh auth status`, `gh auth login`, and the `GITHUB_TOKEN`/credential context used by `gh`)

## Shared conventions
- Use plain markdown with short sections.
- Make the examples copy-pasteable.
- Keep the README short and action-oriented.
- Do not introduce requirements that the scripts do not already need.

## Error handling and reporting
- The README should point readers to the usage guide for step-by-step setup.
- The usage guide should call out the exact failure modes users are most likely to hit when first setting up the template.

## Testing strategy
Verify the docs refresh with lightweight checks:

- confirm the README links to `docs/USING-THE-TEMPLATE.md`
- confirm the usage guide mentions GitHub CLI authentication and all required environment variables
- confirm the usage guide includes an example export block and troubleshooting section

## Acceptance criteria
- The README explains where to find the usage instructions.
- `docs/USING-THE-TEMPLATE.md` documents prerequisites, auth, environment variables, examples, and troubleshooting.
- The documentation is detailed enough for a new consumer to bootstrap and verify the template without guessing.

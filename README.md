# GitHub Secure Repository Template

Security-first starter template for new repositories.

Start with [RUNBOOK.mdx](./RUNBOOK.mdx) for the supported repository creation, cloning, scaffold selection, and verification flow.

## Start here

- Read [RUNBOOK.mdx](./RUNBOOK.mdx) for the full repo-creation flow.
- Use [docs/USING-THE-TEMPLATE.md](./docs/USING-THE-TEMPLATE.md) for manual bootstrap details.
- Review [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md) and [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md) before opening security-sensitive PRs.

## Using the runbook

The interactive runbook requires a Gruntworks runbook viewer. Install instructions:

- **VSCode:** Install the [Gruntworks Runbooks extension](https://marketplace.visualstudio.com/items?itemName=gruntwork-io.runbooks)
- **Web:** View at [runbooks.gruntwork.io](https://runbooks.gruntwork.io/)
- **CLI:** Use the [gruntwork-io/runbooks](https://github.com/gruntwork-io/runbooks) repository for hosting and rendering

## Included baseline

- [SECURITY.md](./SECURITY.md)
- [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md)
- [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md)
- CodeQL, dependency review, Scorecard, and zizmor workflows
- stale-item and branch-pruning automation
- bootstrap and verification scripts for the secure baseline

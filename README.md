# GitHub Secure Repository Template

Security-first starter template for new repositories.

```bash
gh repo create my-org/my-repo --template OWNER/secure-repo-template --private --clone
cd my-repo
./init.sh
./scripts/verify-security.sh
```

Replace `OWNER` with the GitHub account or organization that owns the template repo.

## Start here

- Read [RUNBOOK.mdx](./RUNBOOK.mdx) for the full repo-creation flow.
- Use [docs/USING-THE-TEMPLATE.md](./docs/USING-THE-TEMPLATE.md) for manual bootstrap details.
- Review [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md) and [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md) before opening security-sensitive PRs.

## Included baseline

- [SECURITY.md](./SECURITY.md)
- [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md)
- [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md)
- CodeQL, dependency review, Scorecard, and zizmor workflows
- stale-item and branch-pruning automation
- bootstrap and verification scripts for the secure baseline

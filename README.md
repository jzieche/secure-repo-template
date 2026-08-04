# GitHub Secure Repository Template

This repository is a security-first starter template.

It includes:

- a disclosure policy in [SECURITY.md](./SECURITY.md)
- branch naming guidance in [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md)
- security baseline details in [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md)
- GitHub Actions workflows for CodeQL, dependency review, Scorecard, and zizmor
- scheduled stale-item and branch-pruning automation
- bootstrap and verification scripts for the secure baseline

## Quick Start

The fastest way to get started:

```bash
gh repo create my-org/my-repo --template secure-repo-template --private
cd my-repo
./init.sh
scripts/verify-security.sh
```

The `init.sh` script automates the entire setup process:

- **Auto-detects** your GitHub repository from the current directory
- **Prompts for configuration** with sensible defaults (release team, production reviewers, required checks, wait timers)
- **Applies the security baseline** including branch protection rules, rulesets, and security policies
- **Cleans up template artifacts** automatically (test files, example workflows)
- **Supports resume** – if initialization is interrupted, run `./init.sh` again to resume from the last checkpoint
- **Verifies security** – run `scripts/verify-security.sh` afterward to confirm all settings are correctly applied

The script provides clear feedback at each step and allows previewing changes before applying them (dry-run mode).

## Manual Setup (Advanced)

For detailed step-by-step instructions and environment variable reference, see [docs/USING-THE-TEMPLATE.md](./docs/USING-THE-TEMPLATE.md).

## Before you open a security-sensitive PR

- Review the checklist in `.github/PULL_REQUEST_TEMPLATE.md`
- Confirm the branch name matches [docs/BRANCH-NAMING.md](./docs/BRANCH-NAMING.md)
- Review the security baseline in [docs/SECURITY-SETTINGS.md](./docs/SECURITY-SETTINGS.md)

## What is already configured

- security policy files for disclosure and intake
- CodeQL, dependency review, Scorecard, and zizmor workflows
- stale-item cleanup and branch pruning workflows
- bootstrap and verification scripts for repository security settings

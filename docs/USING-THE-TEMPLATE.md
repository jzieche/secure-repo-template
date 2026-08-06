# Using the Secure Repository Template

This guide covers the manual bootstrap details for the security baseline. For the full repo-creation flow, scaffold selection, GitHub auth, and worktree handoff steps, use [RUNBOOK.mdx](../RUNBOOK.mdx).

## Manual Setup (Advanced Users)

Use the steps below when you want direct control over the bootstrap process.

### Prerequisites

#### Required for all setup modes

- `gh` – GitHub CLI (see https://cli.github.com/)
- `python` – Python 3 (for JSON parsing and utilities)
- `bash` – Bash 4.0 or later (standard on macOS and Linux)
- GitHub authentication: run `gh auth login` first

#### Additional tools for manual setup

- GitHub CLI (`gh`) – for querying and modifying repository settings
- jq – for JSON parsing in scripts
- curl – for GitHub API calls
- Bash 4.0 or later

### Environment Variables

The bootstrap script accepts the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_REPOSITORY` | (auto-detected) | Repository in `owner/repo` format |
| `RELEASE_TEAM_SLUG` | `release-team` | GitHub team slug for release approvals |
| `PRODUCTION_REVIEWERS` | `{"team": "release-team"}` | JSON object defining production approval requirements |
| `PRODUCTION_WAIT_TIMER_MINUTES` | `10` | Deployment wait timer in minutes |
| `REQUIRED_CHECKS` | `CodeQL,Dependency Review` | Comma-separated list of required checks before merge |
| `DRY_RUN` | `0` | Set to `1` to preview changes without applying |

### Manual Bootstrap Steps

1. **Authenticate with GitHub:**
   ```bash
   gh auth login
   gh auth status
   ```

2. **Set environment variables:**
   ```bash
   export GITHUB_REPOSITORY="myorg/myrepo"
   export RELEASE_TEAM_SLUG="my-release-team"
   export PRODUCTION_REVIEWERS='{"team": "my-release-team"}'
   export PRODUCTION_WAIT_TIMER_MINUTES="10"
   export REQUIRED_CHECKS="CodeQL,Dependency Review"
   ```

3. **Run the bootstrap script:**
   ```bash
   ./scripts/bootstrap-security.sh
   ```

### Verifying the Setup

Run the verification script to confirm all settings were applied correctly:

```bash
./scripts/verify-security.sh
```

This script checks:
- Branch protection rules
- Rulesets and naming rules
- Deployment protections
- Required status checks
- Security settings and policies

## Next Steps

After setup:

1. **Review settings:** `gh repo view --web` to see your repository on GitHub
2. **Customize the README:** Update `README.md` with your project details
3. **Set up workflows:** Review `docs/BRANCH-NAMING.md` for development workflow guidance
4. **Configure teams:** Add your release team and required reviewers to your organization
5. **Test with a branch:** Create a test branch following the naming convention and verify protection rules are enforced

## Troubleshooting

### "Required command 'gh' not found"

Install GitHub CLI: https://cli.github.com/

### "Failed to detect GitHub repository"

- Verify you're in the repository directory
- Run `gh auth login` to authenticate
- Verify the repository exists on GitHub

### "Invalid JSON for production reviewers"

Production reviewers must be valid JSON. Examples:

```json
{"team": "release-team"}
{"users": ["user1", "user2"]}
{"team": "release-team", "required_approvals": 2}
```

### Checkpoint resume not working

Delete the checkpoint file and start fresh:

```bash
rm -f .init-state.json
./init.sh
```

## Additional Resources

- [Security Settings Reference](./SECURITY-SETTINGS.md)
- [Branch Naming Conventions](./BRANCH-NAMING.md)
- [Pull Request Template](./.github/PULL_REQUEST_TEMPLATE.md)
- [Security Policy](./SECURITY.md)

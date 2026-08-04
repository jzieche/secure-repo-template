# Using the Secure Repository Template

## Automated Setup (Recommended)

The `init.sh` script provides an automated, interactive way to set up your repository with the security baseline. This is the recommended approach for most users.

### How it works

The `init.sh` script guides you through a multi-phase setup process:

1. **Environment Check** – verifies required tools are installed (GitHub CLI, Python, Bash)
2. **Checkpoint Resume** – detects any previous initialization attempts and offers to resume from that point
3. **Configuration Gathering** – prompts you for configuration values with intelligent defaults:
   - GitHub repository (auto-detected from current directory)
   - Release team slug (default: `release-team`)
   - Production reviewers (JSON format, with smart default based on release team)
   - Production wait timer in minutes (default: `10`)
   - Required checks (comma-separated list, default: `CodeQL,Dependency Review`)
4. **Configuration Summary** – displays all settings for your review and confirmation
5. **Dry-run Preview** – optionally preview changes without applying them
6. **Bootstrap Execution** – applies the security baseline to your repository using `scripts/bootstrap-security.sh`
7. **Template Cleanup** – removes template artifacts (example workflows, test files, etc.)
8. **Initialization Cleanup** – optionally removes the `init.sh` script itself
9. **Verification** – displays next steps including running `scripts/verify-security.sh`

### Resumable from Checkpoints

The script saves its progress at key stages, stored in `.init-state.json`. If initialization is interrupted:

```bash
$ ./init.sh
Starting repository initialization...
Checkpoint found from previous initialization
Resume initialization from checkpoint? (y/n) [y]: y
Resuming from checkpoint...
Checkpoint variables loaded
...
```

If you choose not to resume, the script starts fresh. Either way, you'll be guided through completion.

### Prerequisites

#### For Automated Setup (Recommended)

- `gh` – GitHub CLI (see https://cli.github.com/)
- `python` – Python 3 (for JSON parsing and utilities)
- `bash` – Bash 4.0 or later (standard on macOS and Linux)
- GitHub authentication: run `gh auth login` first

#### For Manual Setup (Advanced)

- GitHub CLI (`gh`) – for querying and modifying repository settings
- jq – for JSON parsing in scripts
- curl – for GitHub API calls
- Bash 4.0 or later
- GitHub authentication: run `gh auth login` first

## Manual Setup (Advanced Users)

If you prefer to run the initialization steps manually or need more control over the process, you can use the underlying bootstrap script directly.

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
   scripts/bootstrap-security.sh
   ```

4. **Verify the configuration:**
   ```bash
   scripts/verify-security.sh
   ```

### What the Bootstrap Script Does

The `scripts/bootstrap-security.sh` script applies the security baseline to your repository:

- Enables branch protection rules on main/master branch
- Configures required status checks based on `REQUIRED_CHECKS`
- Sets up production deployment protection with wait timers
- Applies branch naming rules via rulesets
- Enables automatic dependency updates via Dependabot
- Configures security scanning (CodeQL, dependency review)
- Sets appropriate visibility and permissions

### Verifying the Setup

Run the verification script to confirm all settings were applied correctly:

```bash
scripts/verify-security.sh
```

This script checks:
- Branch protection rules
- Rulesets and naming rules
- Deployment protections
- Required status checks
- Security settings and policies

## Next Steps

After setup (automated or manual):

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

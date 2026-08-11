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

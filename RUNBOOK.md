# Gruntworks Repo Creation Runbook

## Purpose

Use this runbook to create a new repository from the template, apply the shared security baseline, choose one scaffold, and verify the result.

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Access to the target GitHub organization and repository
- Bash available in the template repo
- `rsync` installed and on `PATH` before copying scaffold files
- `init.sh` present in the repo root
- `scripts/verify-security.sh` present under `scripts/`

## 1) Create the repository

```bash
gh auth login
gh auth status
gh repo create acme-inc/example-service --template OWNER/secure-repo-template --private --clone
cd example-service
./init.sh
./scripts/verify-security.sh
```

Replace `OWNER` with the GitHub account or organization that owns the template repo.

## 2) Complete post-setup work

- Review the repo settings created by the bootstrap
- Confirm the release team and production reviewers are correct
- Confirm branch protection, rulesets, and security settings are active
- Update `README.md` with repo-specific details
- Review `docs/BRANCH-NAMING.md` before opening the first PR
- Review `docs/SECURITY-SETTINGS.md` before changing security-sensitive settings

## 3) Choose one scaffold

### Helm

Use Helm when the repo should ship Kubernetes manifests as a chart.

- `helm` installed and on `PATH`

```bash
if [ -d scaffolds/helm ]; then
  rsync -a --exclude 'README.md' scaffolds/helm/ ./
  helm lint .
  helm template test-release .
  rm -rf scaffolds/helm scaffolds/terraform-module
else
  echo "Helm scaffold is not available in this checkout yet; it will appear once the later template phase lands."
fi
```

### Terraform module

Use Terraform when the repo should publish reusable infrastructure code.

- `terraform` installed and on `PATH`

```bash
if [ -d scaffolds/terraform-module ]; then
  rsync -a --exclude 'README.md' scaffolds/terraform-module/ ./
  terraform fmt -check
  terraform init -backend=false
  terraform validate
  rm -rf scaffolds/helm scaffolds/terraform-module
else
  echo "Terraform module scaffold is not available in this checkout yet; it will appear once the later template phase lands."
fi
```

## 4) Verify and hand off

- Confirm only the intended scaffold is present
- Run the expected validation command set for that scaffold
- Record any repo-specific changes made during setup
- Hand off the repository with the verification notes

## Troubleshooting

- If `gh auth status` fails, run `gh auth login` again
- If repository setup fails, confirm the GitHub token has the needed permissions
- If scaffold validation fails, confirm the tool is installed and the scaffold was copied into the repo root
- If a branch, team, or reviewer value is wrong, fix it and rerun `./init.sh`

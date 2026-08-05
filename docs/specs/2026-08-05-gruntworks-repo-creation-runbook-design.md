# Gruntworks Repo Creation Runbook Design

## Goal
Create a single, practical runbook that helps Gruntworks engineers and client teams create new repositories from this template, complete the security baseline, and choose the right starter scaffold for Helm or Terraform modules.

## Scope
This slice adds the runbook and the starter scaffolds it references:

- `RUNBOOK.md`
- `scaffolds/helm/`
- `scaffolds/terraform-module/`
- `README.md` updates to point to the runbook
- `docs/USING-THE-TEMPLATE.md` updates only where needed to avoid duplicated guidance

## Non-goals
- No new GitHub Actions workflows
- No repository settings automation changes
- No new scaffold types beyond Helm and Terraform modules
- No attempts to make the scaffolds fully production-complete for every use case

## Design summary
The runbook is the canonical end-to-end guide for repo creation. It starts with template repository creation, runs through initialization and verification, then branches into scaffold-specific setup for Helm or Terraform modules. The README stays short and points readers to the runbook. Existing setup docs remain as supporting references, but the runbook becomes the primary path for creating new repos from the template.

## File-by-file design

### `RUNBOOK.md`
Organize the runbook into four phases:

1. **Create the new repository**
   - create a repo from the template
   - authenticate with `gh`
   - run `./init.sh`
   - verify the security baseline

2. **Complete the common post-setup work**
   - configure teams and reviewers
   - configure secrets and repo-specific settings
   - review branch protection and required checks
   - customize the README and repo metadata

3. **Choose and apply a scaffold**
   - Helm chart scaffold
   - Terraform module scaffold
   - guidance for when to pick each one

4. **Verify and hand off**
   - run validation commands
   - confirm the repo is ready for normal development
   - note common failure modes and recovery steps

The document should be written as a runbook, not a conceptual essay: short sections, copy-pasteable commands, clear checkpoints, and explicit success criteria.

### `scaffolds/helm/`
Provide a minimal Helm chart starter that can be copied into a new repo. It should include:

- `Chart.yaml`
- `values.yaml`
- `templates/_helpers.tpl`
- `templates/deployment.yaml`
- `templates/service.yaml`
- a lightweight chart README or inline guidance if needed

The scaffold should demonstrate:

- standard chart metadata
- values-driven configuration
- safe defaults for image, replicas, and service exposure
- basic template structure that teams can extend

### `scaffolds/terraform-module/`
Provide a minimal Terraform module starter that can be copied into a new repo. It should include:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `versions.tf`
- `terraform.tfvars.example`
- optional module README or inline guidance if needed

The scaffold should demonstrate:

- required provider/version constraints
- typed variables with descriptions
- module outputs
- example variable overrides
- state-safe module structure suitable for reuse

### `README.md`
Keep the README concise and update it so it:

- explains that the repository is a template
- points to `RUNBOOK.md` for repo creation and scaffold setup
- preserves the existing security-first positioning

### `docs/USING-THE-TEMPLATE.md`
Trim or reframe overlapping setup guidance so this file does not duplicate the runbook. It should remain a supporting reference for manual bootstrap details, while the runbook carries the main user journey.

## Validation and error handling
The runbook should include checkpoints after each major phase:

- repo creation success
- `init.sh` completion
- security baseline verification
- scaffold selection and setup
- final validation for Helm or Terraform

It should also include a troubleshooting section for:

- missing `gh` authentication
- permission errors when applying repo settings
- invalid repository or team identifiers
- scaffold setup failures or missing dependencies

## Shared conventions
- Use plain markdown and short, actionable headings.
- Prefer commands and checklists over prose.
- Keep the Helm and Terraform scaffolds minimal, readable, and easy to customize.
- Reuse the existing template security language where possible instead of inventing new policy text.

## Acceptance criteria
- `RUNBOOK.md` exists and is the primary repo-creation guide.
- The runbook covers repo creation, initialization, verification, common post-setup work, and scaffold selection.
- Helm and Terraform module starter scaffolds exist and are referenced by the runbook.
- The README points users to the runbook.
- Overlapping setup guidance is not duplicated unnecessarily across docs.

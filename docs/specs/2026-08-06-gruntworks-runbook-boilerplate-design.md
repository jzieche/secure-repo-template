# Gruntwork Runbook Boilerplate Design

## Overview

This project upgrades the repository-creation runbook from a basic scripted MDX flow into a Gruntwork-style runbook that uses the documented authoring blocks and Boilerplate-templated scaffolds.

The goal is to make the runbook easier to follow, more consistent with Gruntwork documentation, and safer to maintain by keeping GitHub authentication, repo setup, and scaffold application in clearly separated blocks.

## Goals

- Use `RUNBOOK.mdx` as the primary entry point.
- Add a dedicated GitHub authentication step before any repository operations.
- Keep repository creation and initialization in the runbook flow.
- Convert the Helm and Terraform scaffolds to Boilerplate templates.
- Keep scaffold-specific variables local to each scaffold.
- Preserve the current repo creation workflow and validation behavior.
- Make scaffold generation deterministic and easy to validate.

## Non-goals

- Redesigning the template repository itself.
- Introducing new scaffold types beyond Helm and Terraform.
- Changing the bootstrap logic in `init.sh` beyond what is needed to support the new runbook flow.
- Reworking repository policy or security defaults outside the runbook.

## Current State

The repository currently has:

- `RUNBOOK.mdx` with basic `<Inputs>` and `<Command>` blocks.
- Shell scripts under `scripts/runbook/` for repo creation, initialization, and scaffold application.
- Static scaffold directories under `scaffolds/helm/` and `scaffolds/terraform-module/`.

The current scaffold roots already contain the files that should become templates:

- Helm: `Chart.yaml`, `values.yaml`, `README.md`, `.helmignore`, and `templates/*.yaml`
- Terraform: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `terraform.tfvars.example`

## Proposed Design

### 1) Runbook flow

`RUNBOOK.mdx` will become the interactive orchestration layer for the full workflow:

1. Authenticate GitHub access with a dedicated GitHub auth block.
2. Collect repository configuration with `<Inputs>`.
3. Create the repository from the template and clone it.
4. Run the repository initialization script.
5. Present a mutually exclusive choice between Helm and Terraform scaffolds.
6. Apply the selected Boilerplate template.
7. Validate the generated output with scaffold-specific checks.
8. Finish with a short handoff checklist.

The GitHub auth step belongs first so every later command that needs GitHub credentials can rely on the same authenticated session.

### 2) Repository creation and initialization

The repo-creation portion stays in the runbook but becomes more explicit and less script-centric:

- Inputs remain the source of truth for `OrgName`, `RepoName`, `TemplateOwner`, and `Visibility`.
- The repository creation step still uses `gh` and the template repo.
- The initialization step remains a separate command so bootstrap logic stays isolated and testable.

This keeps the setup pipeline readable while avoiding a monolithic script that mixes GitHub auth, repo provisioning, and local validation.

### 3) Scaffold templating model

Each scaffold gets its own `boilerplate.yml` and template tree.

#### Helm scaffold

The Helm scaffold will define variables for:

- chart name
- application name
- image repository and tag
- replica count
- service type and port
- resource requests and limits
- optional metadata labels and annotations

The template tree will cover the existing Helm files so the scaffold still produces a valid chart layout.

#### Terraform module scaffold

The Terraform scaffold will define variables for:

- module name
- description
- required Terraform version
- provider constraints
- input variable metadata
- output metadata
- tags and owner/reference fields

The template tree will cover the existing module files so the scaffold remains a normal Terraform module after generation.

### 4) Validation strategy

Each scaffold will include validation that matches the generated output:

- Helm: ensure the chart files render and the output structure is valid for Helm packaging.
- Terraform: ensure the module has the expected source files and basic formatting/structure checks pass.

Validation should fail loudly with scaffold-specific messages so users can tell which path needs attention.

### 5) File organization

The design keeps the current top-level layout but changes ownership of responsibilities:

- `RUNBOOK.mdx` owns the interactive flow.
- `scaffolds/helm/` owns Helm template variables and template files.
- `scaffolds/terraform-module/` owns Terraform template variables and template files.
- `scripts/runbook/` remains only for helper steps that are not naturally represented as templated scaffolds.

## Error Handling

- GitHub authentication failures should stop the flow early with an actionable message.
- Repository creation failures should surface the `gh` error directly.
- Scaffold application failures should identify which scaffold failed and preserve the generated output for inspection.
- Validation failures should not be swallowed; the runbook should tell the user exactly which scaffold check failed.

## Testing and Verification

Implementation should be validated with the smallest end-to-end checks that prove the new runbook works:

- confirm `RUNBOOK.mdx` parses with the expected block structure
- confirm repository setup still works with authenticated GitHub CLI access
- confirm Helm scaffold generation produces the expected chart files
- confirm Terraform scaffold generation produces the expected module files
- confirm scaffold-specific validation fails when required files are missing or malformed

## Migration Notes

The migration should be incremental:

1. Convert the runbook orchestration to proper MDX blocks.
2. Add the GitHub auth step.
3. Introduce Boilerplate metadata to the Helm scaffold.
4. Introduce Boilerplate metadata to the Terraform scaffold.
5. Update ignore files and any scaffold-specific documentation that no longer matches the new layout.

This sequencing minimizes risk because the runbook remains usable while each scaffold is converted.

## Open Questions Resolved

- The runbook should keep only one scaffold path active at a time.
- GitHub authentication belongs in the runbook, not in the scaffold templates.
- The Helm and Terraform scaffolds should remain separate so their validation and variables stay focused.


# Gruntwork Runbook Boilerplate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the repo-creation runbook to a Gruntwork-style MDX flow with GitHub auth, GitClone-driven worktree setup, and Boilerplate-templated Helm and Terraform scaffolds.

**Architecture:** `RUNBOOK.mdx` becomes the orchestration layer: authenticate to GitHub, create the repo, clone the new repo into the workspace, initialize it, then render exactly one scaffold into the cloned worktree and validate it. The Helm and Terraform scaffold directories become standalone Boilerplate templates with local `boilerplate.yml` files so each scaffold owns its own variables and generated output.

**Tech Stack:** MDX runbook blocks (`GitHubAuth`, `Command`, `GitClone`, `Template`, `Check`), GitHub CLI, Bash, Gruntwork Boilerplate, Helm, Terraform.

## Global Constraints

- Use `RUNBOOK.mdx` as the primary entry point.
- Add a dedicated GitHub authentication step before any repository operations.
- Keep repository creation and initialization in the runbook flow.
- Convert the Helm and Terraform scaffolds to Boilerplate templates.
- Keep scaffold-specific variables local to each scaffold.
- Preserve the current repo creation workflow and validation behavior.
- Make scaffold generation deterministic and easy to validate.

---

### Task 1: Rewire the runbook startup flow and GitHub auth

**Files:**
- Modify: `RUNBOOK.mdx`
- Modify: `scripts/runbook/create-repo-from-template.sh`
- Modify: `scripts/runbook/initialize-repo.sh`
- Modify: `README.md`
- Delete: `scripts/runbook/apply-helm-scaffold.sh`
- Delete: `scripts/runbook/apply-terraform-scaffold.sh`

**Interfaces:**
- Consumes: `OrgName`, `RepoName`, `TemplateOwner`, `Visibility` from the existing `repo-config` inputs block.
- Produces: a runbook flow that authenticates with GitHub, creates the repo without cloning it, clones the new repo via `GitClone`, and runs repo initialization against the cloned worktree.

- [ ] **Step 1: Rewrite the runbook block flow**

Use this block order in `RUNBOOK.mdx`:

```mdx
<GitHubAuth id="gh-auth" title="Authenticate to GitHub" />
<Inputs id="repo-config">...</Inputs>
<Command id="create-repo" githubAuthId="gh-auth" inputsId="repo-config" path="scripts/runbook/create-repo-from-template.sh" />
<GitClone id="clone-new-repo" githubAuthId="gh-auth" prefilledUrl="https://github.com/{{ .inputs.OrgName }}/{{ .inputs.RepoName }}" prefilledLocalPath="./{{ .inputs.RepoName }}" />
<Command id="initialize-repo" githubAuthId="gh-auth" path="scripts/runbook/initialize-repo.sh" />
<Template id="helm-scaffold" path="scaffolds/helm" target="worktree" />
<Check id="helm-verify" command='cd "$REPO_FILES" && helm lint . && helm template test-release .' />
<Template id="terraform-scaffold" path="scaffolds/terraform-module" target="worktree" />
<Check id="terraform-verify" command='cd "$REPO_FILES" && terraform fmt -check && terraform init -backend=false && terraform validate' />
```

Keep the existing “choose one scaffold” wording in markdown so only one scaffold path is used on a given run.

- [ ] **Step 2: Make repo creation stop cloning**

Edit `scripts/runbook/create-repo-from-template.sh` so the `gh repo create` command drops `--clone` and only creates the repository:

```bash
#!/usr/bin/env bash
set -euo pipefail

gh repo create "{{ .inputs.OrgName }}/{{ .inputs.RepoName }}" --template "{{ .inputs.TemplateOwner }}/secure-repo-template" --{{ .inputs.Visibility }}
```

- [ ] **Step 3: Make initialization run against the cloned worktree**

Edit `scripts/runbook/initialize-repo.sh` so it uses the workspace-provided repo path instead of the raw repo name:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "${REPO_FILES:?REPO_FILES is not set}"
./init.sh
./scripts/verify-security.sh
```

- [ ] **Step 4: Remove obsolete scaffold-application scripts**

Delete `scripts/runbook/apply-helm-scaffold.sh` and `scripts/runbook/apply-terraform-scaffold.sh`; the new `<Template>` blocks replace them.

- [ ] **Step 5: Refresh the top-level README quick start**

Replace the old direct shell quick-start with a short pointer to `RUNBOOK.mdx` as the supported flow.

Run:

```bash
git diff --check
rg -n '<GitHubAuth|<GitClone|<Template|<Check>' RUNBOOK.mdx
bash -n scripts/runbook/create-repo-from-template.sh scripts/runbook/initialize-repo.sh
```

Expected: `git diff --check` is clean, the block search shows the new runbook wiring, and both shell scripts pass syntax check.

---

### Task 2: Convert the Helm scaffold into a Boilerplate template

**Files:**
- Create: `scaffolds/helm/boilerplate.yml`
- Modify: `scaffolds/helm/Chart.yaml`
- Modify: `scaffolds/helm/values.yaml`
- Modify: `scaffolds/helm/README.md`
- Modify: `scaffolds/helm/.helmignore`
- Modify: `scaffolds/helm/templates/_helpers.tpl`
- Modify: `scaffolds/helm/templates/deployment.yaml`
- Modify: `scaffolds/helm/templates/service.yaml`

**Interfaces:**
- Consumes: the Helm scaffold’s own Boilerplate variables.
- Produces: a self-contained Helm template directory that can be rendered into a cloned repo with `target="worktree"` and then validated with Helm.

- [ ] **Step 1: Add the Helm Boilerplate manifest**

Create `scaffolds/helm/boilerplate.yml` with variables for:

- `ChartName`
- `Description`
- `Version`
- `AppVersion`
- `ImageRepository`
- `ImageTag`
- `ImagePullPolicy`
- `ReplicaCount`
- `ServiceType`
- `ServicePort`
- `ContainerPort`
- `TargetPort`
- `NameOverride`
- `FullnameOverride`
- `Resources`

Keep the current Helm defaults so the rendered chart remains valid without extra user input.

- [ ] **Step 2: Template the chart metadata and helper names**

Update `Chart.yaml` and `_helpers.tpl` so the chart name, description, version, and helper template names come from the Boilerplate variables instead of the hard-coded `example-app` values.

- [ ] **Step 3: Template the workload and service manifests**

Update `templates/deployment.yaml`, `templates/service.yaml`, and `values.yaml` to use the same variable names from `boilerplate.yml` so the generated chart matches the user’s chosen chart name, image, replica count, and service settings.

- [ ] **Step 4: Refresh the scaffold README and ignore file**

Rewrite `scaffolds/helm/README.md` so it explains that the directory is a Boilerplate template, not a manual copy-paste scaffold, and update `scaffolds/helm/.helmignore` so generated runbook files, `boilerplate.yml`, and scaffold authoring files stay out of Helm packaging.

- [ ] **Step 5: Render and validate the Helm template**

Run:

```bash
boilerplate --template-url scaffolds/helm --output-folder /tmp/secure-repo-template-helm --non-interactive
helm lint /tmp/secure-repo-template-helm
helm template test-release /tmp/secure-repo-template-helm
```

Expected: Boilerplate renders the chart into the temp folder, `helm lint` succeeds, and `helm template` prints a manifest without errors.

---

### Task 3: Convert the Terraform scaffold into a Boilerplate template

**Files:**
- Create: `scaffolds/terraform-module/boilerplate.yml`
- Modify: `scaffolds/terraform-module/main.tf`
- Modify: `scaffolds/terraform-module/variables.tf`
- Modify: `scaffolds/terraform-module/outputs.tf`
- Modify: `scaffolds/terraform-module/versions.tf`
- Modify: `scaffolds/terraform-module/terraform.tfvars.example`
- Modify: `scaffolds/terraform-module/README.md`

**Interfaces:**
- Consumes: the Terraform scaffold’s own Boilerplate variables.
- Produces: a self-contained Terraform module template that renders into the cloned repo and validates with the standard Terraform CLI checks.

- [ ] **Step 1: Add the Terraform Boilerplate manifest**

Create `scaffolds/terraform-module/boilerplate.yml` with variables for:

- `Name`
- `Description`
- `Enabled`
- `Tags`
- `RequiredVersion`
- `RequiredProviders`

Keep the current module defaults, but make the name, description, tags, and version constraints editable from the template form.

- [ ] **Step 2: Template the module implementation files**

Update `main.tf`, `variables.tf`, and `outputs.tf` so the normalized module name, description, enabled flag, and merged tags are driven by the Boilerplate variables.

- [ ] **Step 3: Template the Terraform version constraints**

Update `versions.tf` so `required_version` comes from `RequiredVersion`, and render any `required_providers` entries from `RequiredProviders` when the user supplies them.

- [ ] **Step 4: Refresh the scaffold README and tfvars example**

Rewrite `scaffolds/terraform-module/README.md` so it explains that the directory is a Boilerplate template, and update `terraform.tfvars.example` so it matches the new variable names and defaults.

- [ ] **Step 5: Render and validate the Terraform template**

Run:

```bash
boilerplate --template-url scaffolds/terraform-module --output-folder /tmp/secure-repo-template-terraform --non-interactive
cd /tmp/secure-repo-template-terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

Expected: Boilerplate renders the module into the temp folder, formatting passes, `terraform init -backend=false` succeeds, and `terraform validate` reports no errors.

---

### Task 4: Final smoke test and doc alignment

**Files:**
- Modify: `docs/USING-THE-TEMPLATE.md`

**Interfaces:**
- Consumes: the completed runbook flow and both Boilerplate scaffolds.
- Produces: onboarding docs that point at the MDX runbook first, plus a final end-to-end smoke test record for the finished flow.

- [ ] **Step 1: Align the onboarding docs with the new flow**

Update `docs/USING-THE-TEMPLATE.md` so it still points people at `RUNBOOK.mdx`, but no longer implies that scaffold application is a manual `rsync`-style copy step.

- [ ] **Step 2: Smoke-test the completed template directories**

Run the same Boilerplate render commands from Tasks 2 and 3 again, then validate that the rendered repos still pass their native tool checks after the doc changes.

- [ ] **Step 3: Verify the repo is clean**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors and only the intended tracked changes remain.

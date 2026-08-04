# Core Security Scans Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the repository’s primary security-scanning GitHub Actions workflows for CodeQL, dependency review, Scorecard, and zizmor.

**Architecture:** Keep each workflow single-purpose and independently reviewable, but apply the same hardening baseline everywhere: pinned third-party actions, explicit permissions, bounded runtime, and clear trigger scope. CodeQL and Scorecard publish persistent security signals, dependency-review blocks risky dependency changes in pull requests, and zizmor audits the workflow files themselves so the template models secure GitHub Actions patterns.

**Tech Stack:** GitHub Actions, YAML, CodeQL, dependency-review-action, OpenSSF Scorecard, zizmorcore/zizmor

## Global Constraints

- The repository starts empty, so file creation must be self-contained.
- Content should be template-friendly and not assume an existing org structure beyond a security owner.
- The license choice is fixed to MIT.
- No secret-scan audit workflow in this slice.
- No stale-issue or branch-pruning automation in this slice.
- No bootstrap scripts or repository settings in this slice.
- No Dependabot configuration changes in this slice.
- All workflows pin third-party actions to full commit SHAs.
- All workflows set explicit, minimal `permissions`.
- All workflows use bounded execution time.

---

### Task 1: Add the CodeQL workflow

**Files:**
- Create: `.github/workflows/codeql.yml`

**Interfaces:**
- Consumes: repository source code and the default branch state
- Produces: CodeQL analysis results and SARIF upload for pull requests and default-branch pushes

- [ ] **Step 1: Write the workflow file**

```yaml
name: CodeQL

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

permissions:
  actions: read
  contents: read
  security-events: write

jobs:
  detect:
    name: Detect languages
    runs-on: ubuntu-latest
    timeout-minutes: 10
    outputs:
      languages: ${{ steps.detect.outputs.languages }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Detect supported languages
        id: detect
        shell: bash
        run: |
          set -euo pipefail
          languages=()

          if find . -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name 'package.json' -o -name 'tsconfig.json' \) | grep -q .; then
            languages+=("javascript-typescript")
          fi

          if find . -type f \( -name '*.py' -o -name 'pyproject.toml' -o -name 'requirements.txt' \) | grep -q .; then
            languages+=("python")
          fi

          if [ "${#languages[@]}" -eq 0 ]; then
            echo "languages=[]" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          json=$(printf '%s\n' "${languages[@]}" | jq -R . | jq -cs .)
          echo "languages=$json" >> "$GITHUB_OUTPUT"

  analyze:
    name: Analyze
    needs: detect
    if: needs.detect.outputs.languages != '[]'
    runs-on: ubuntu-latest
    timeout-minutes: 60
    concurrency:
      group: codeql-${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true
    strategy:
      fail-fast: false
      matrix:
        language: ${{ fromJson(needs.detect.outputs.languages) }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Initialize CodeQL
        uses: github/codeql-action/init@e60ea984bd3baa95954f2856bcf24f9eaba46637
        with:
          languages: ${{ matrix.language }}

      - name: Autobuild
        uses: github/codeql-action/autobuild@e60ea984bd3baa95954f2856bcf24f9eaba46637

      - name: Perform CodeQL analysis
        uses: github/codeql-action/analyze@e60ea984bd3baa95954f2856bcf24f9eaba46637
```

- [ ] **Step 2: Verify the workflow file**

Run:
```bash
test -f .github/workflows/codeql.yml && grep -q "security-events: write" .github/workflows/codeql.yml && grep -q "fromJson(needs.detect.outputs.languages)" .github/workflows/codeql.yml && grep -q "pull_request" .github/workflows/codeql.yml && grep -q "push" .github/workflows/codeql.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add .github/workflows/codeql.yml
git commit -m "ci: add CodeQL workflow"
```

### Task 2: Add the dependency review workflow

**Files:**
- Create: `.github/workflows/dependency-review.yml`

**Interfaces:**
- Consumes: pull request dependency changes
- Produces: a pass/fail gate for dependency risk in pull requests

- [ ] **Step 1: Write the workflow file**

```yaml
name: Dependency Review

on:
  pull_request:
    branches:
      - main

permissions:
  contents: read
  pull-requests: read

jobs:
  dependency-review:
    name: Dependency Review
    runs-on: ubuntu-latest
    timeout-minutes: 30
    concurrency:
      group: dependency-review-${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true

    steps:
      - name: Checkout repository
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Run dependency review
        uses: actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294
        with:
          fail-on-severity: high
          allow-licenses: MIT,Apache-2.0,BSD-2-Clause,BSD-3-Clause,ISC,CC0-1.0,Unlicense
          fail-on-scopes: runtime
          vulnerability-check: true
          license-check: true
```

- [ ] **Step 2: Verify the workflow file**

Run:
```bash
test -f .github/workflows/dependency-review.yml && grep -q "pull-requests: read" .github/workflows/dependency-review.yml && grep -q "fail-on-severity: high" .github/workflows/dependency-review.yml && grep -q "actions/dependency-review-action@" .github/workflows/dependency-review.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add .github/workflows/dependency-review.yml
git commit -m "ci: add dependency review workflow"
```

### Task 3: Add the Scorecard workflow

**Files:**
- Create: `.github/workflows/scorecard.yml`

**Interfaces:**
- Consumes: repository metadata and default-branch activity
- Produces: OpenSSF Scorecard results and Security-tab upload

- [ ] **Step 1: Write the workflow file**

```yaml
name: Scorecard

on:
  schedule:
    - cron: "0 3 * * 1"
  push:
    branches:
      - main

permissions:
  contents: read
  issues: read
  id-token: write
  pull-requests: read
  checks: read
  security-events: write

jobs:
  analysis:
    name: Scorecard analysis
    runs-on: ubuntu-latest
    timeout-minutes: 30
    concurrency:
      group: scorecard-${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true

    steps:
      - name: Checkout repository
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Run Scorecard analysis
        uses: ossf/scorecard-action@2d1146689b8cda280b9bc96326124645441f03bc
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          results_file: scorecard-results.sarif
          results_format: sarif
          publish_results: true
```

- [ ] **Step 2: Verify the workflow file**

Run:
```bash
test -f .github/workflows/scorecard.yml && grep -q "schedule:" .github/workflows/scorecard.yml && grep -q "publish_results: true" .github/workflows/scorecard.yml && grep -q "results_format: sarif" .github/workflows/scorecard.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add .github/workflows/scorecard.yml
git commit -m "ci: add Scorecard workflow"
```

### Task 4: Add the zizmor workflow

**Files:**
- Create: `.github/workflows/zizmor.yml`

**Interfaces:**
- Consumes: workflow file changes in pull requests
- Produces: a GitHub Actions security audit report with failures for unsafe workflow patterns

- [ ] **Step 1: Write the workflow file**

```yaml
name: zizmor

on:
  pull_request:
    paths:
      - ".github/workflows/**"

permissions:
  contents: read
  security-events: write

jobs:
  audit:
    name: Audit workflows
    runs-on: ubuntu-latest
    timeout-minutes: 20
    concurrency:
      group: zizmor-${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true

    steps:
      - name: Checkout repository
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Run zizmor
        uses: zizmorcore/zizmor-action@3dc1ecc9bcb9e94e9b2c709687979e1298497054
        with:
          inputs: .github/workflows
          collect: workflows
          persona: pedantic
          online-audits: true
          advanced-security: true
```

- [ ] **Step 2: Verify the workflow file**

Run:
```bash
test -f .github/workflows/zizmor.yml && grep -q "persona: pedantic" .github/workflows/zizmor.yml && grep -q "pull_request" .github/workflows/zizmor.yml && grep -q "zizmorcore/zizmor-action@" .github/workflows/zizmor.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add .github/workflows/zizmor.yml
git commit -m "ci: add zizmor workflow"
```

### Task 5: Final workflow validation

**Files:**
- Inspect: `.github/workflows/codeql.yml`
- Inspect: `.github/workflows/dependency-review.yml`
- Inspect: `.github/workflows/scorecard.yml`
- Inspect: `.github/workflows/zizmor.yml`

**Interfaces:**
- Consumes: all workflow files created in Tasks 1-4
- Produces: a validated workflow bundle ready for the next slice

- [ ] **Step 1: Check the workflow files for consistency**

Run:
```bash
test -f .github/workflows/codeql.yml && test -f .github/workflows/dependency-review.yml && test -f .github/workflows/scorecard.yml && test -f .github/workflows/zizmor.yml && ! grep -R "uses: " .github/workflows | grep -vE '@[0-9a-f]{40}'
```

Expected: the `grep -v` check returns no lines, which means every `uses:` entry is pinned to a full commit SHA.

- [ ] **Step 2: Confirm the slice stayed in scope**

Run:
```bash
find .github/workflows -maxdepth 1 -type f | sort
```

Expected: only `codeql.yml`, `dependency-review.yml`, `scorecard.yml`, and `zizmor.yml` are present for this slice.

- [ ] **Step 3: Commit the final validation state if needed**

```bash
git add .github/workflows
git commit -m "ci: finalize core security scan workflows"
```

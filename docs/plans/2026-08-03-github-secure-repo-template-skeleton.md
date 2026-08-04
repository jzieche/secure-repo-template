# GitHub Secure Repository Template Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the repository skeleton and policy files for the secure template baseline.

**Architecture:** This phase is pure file creation. Keep the repository landing page, disclosure policy, review gates, and issue intake intentionally small and reusable so later workflow and automation phases can build on them without rewriting the foundation. Group files by responsibility: general repository metadata, security policy, and contribution intake.

**Tech Stack:** Markdown, YAML, MIT License text

## Global Constraints

- The repository starts empty, so file creation must be self-contained.
- Content should be template-friendly and not assume an existing org structure beyond a security owner.
- The license choice is fixed to MIT.
- No GitHub Actions workflows yet.
- No Dependabot configuration yet.
- No bootstrap or verification scripts yet.
- No rulesets, repository settings, or GitHub API automation yet.

---

### Task 1: Add core repository metadata

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `.gitattributes`

**Interfaces:**
- Consumes: nothing
- Produces: the repository landing page, license text, and line-ending policy used by all later template files

- [ ] **Step 1: Write the files**

```markdown
# GitHub Secure Repository Template

This repository is a security-first starter template.

It begins with:

- a concise overview in this README
- the MIT License
- line-ending normalization in `.gitattributes`

Later phases add workflows, rulesets, and automation.
```

```text
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

```gitattributes
* text=auto eol=lf
```

- [ ] **Step 2: Verify the files exist and contain the expected anchors**

Run:
```bash
test -f README.md && test -f LICENSE && test -f .gitattributes && grep -q "security-first starter template" README.md && grep -q "MIT License" LICENSE && grep -q "eol=lf" .gitattributes
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add README.md LICENSE .gitattributes
git commit -m "docs: add repository metadata for secure template"
```

### Task 2: Add security policy and contribution entry points

**Files:**
- Create: `SECURITY.md`
- Create: `.github/CODEOWNERS`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`
- Create: `.github/ISSUE_TEMPLATE/security-bug-report.yml`

**Interfaces:**
- Consumes: the repository metadata created in Task 1
- Produces: the disclosure policy, review routing, pull request checklist, and security report form used by contributors

- [ ] **Step 1: Write the files**

```markdown
# Security Policy

## Reporting a Vulnerability

Please report security issues privately.

Include:

- a short summary
- affected component or file
- steps to reproduce
- impact or severity
- any supporting proof-of-concept

We will acknowledge reports as quickly as possible and provide a remediation timeline when we triage the issue.

## Supported Versions

Use the latest template-derived repository version unless a project-specific policy says otherwise.
```

```text
# Replace @security-team with the repository's actual security owner handle.
.github/ @security-team
scripts/ @security-team
SECURITY.md @security-team
```

```markdown
## Security Review

- [ ] I considered the security impact of this change.
- [ ] I ran validation or tests where relevant.
- [ ] I reviewed any permission or workflow-related changes carefully.
```

```yaml
name: Security bug report
description: Report a security issue privately and include enough detail to reproduce it.
title: "[Security]: "
labels:
  - security
body:
  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: Briefly describe the issue.
    validations:
      required: true
  - type: input
    id: component
    attributes:
      label: Affected component
      description: File, module, workflow, or service affected.
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Reproduction steps
      description: List the steps needed to reproduce the issue.
    validations:
      required: true
  - type: textarea
    id: impact
    attributes:
      label: Impact
      description: Describe the potential impact or severity.
    validations:
      required: true
  - type: textarea
    id: poc
    attributes:
      label: Proof of concept or supporting context
      description: Optional evidence, screenshots, logs, or sample input.
    validations:
      required: false
```

- [ ] **Step 2: Verify the policy files and templates**

Run:
```bash
test -f SECURITY.md && test -f .github/CODEOWNERS && test -f .github/PULL_REQUEST_TEMPLATE.md && test -f .github/ISSUE_TEMPLATE/security-bug-report.yml && grep -q "Reporting a Vulnerability" SECURITY.md && grep -q "Security Review" .github/PULL_REQUEST_TEMPLATE.md && grep -q "Security bug report" .github/ISSUE_TEMPLATE/security-bug-report.yml
```

Expected: exit code `0`

- [ ] **Step 3: Commit the task**

```bash
git add SECURITY.md .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md .github/ISSUE_TEMPLATE/security-bug-report.yml
git commit -m "docs: add security policy and contributor templates"
```

### Task 3: Final validation and cleanup

**Files:**
- Inspect: `README.md`
- Inspect: `LICENSE`
- Inspect: `.gitattributes`
- Inspect: `SECURITY.md`
- Inspect: `.github/CODEOWNERS`
- Inspect: `.github/PULL_REQUEST_TEMPLATE.md`
- Inspect: `.github/ISSUE_TEMPLATE/security-bug-report.yml`

**Interfaces:**
- Consumes: all files created in Tasks 1 and 2
- Produces: a validated skeleton that matches the spec and is ready for the next implementation phase

- [ ] **Step 1: Run a final repository check**

Run:
```bash
test -f README.md && test -f LICENSE && test -f .gitattributes && test -f SECURITY.md && test -f .github/CODEOWNERS && test -f .github/PULL_REQUEST_TEMPLATE.md && test -f .github/ISSUE_TEMPLATE/security-bug-report.yml && git diff --check
```

Expected: exit code `0`

- [ ] **Step 2: Confirm the scope stayed limited**

Run:
```bash
find . -maxdepth 2 -type f | sort
```

Expected: only the skeleton and policy files from the spec plus the plan/spec docs are present; no workflows, scripts, or dependency automation files have been added.

- [ ] **Step 3: Commit the final validation state if needed**

```bash
git add .
git commit -m "docs: finalize secure template skeleton"
```

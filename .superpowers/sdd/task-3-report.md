# Task 3 Report

## What I implemented
- Added the Helm scaffold under `scaffolds/helm/`.
- Created:
  - `Chart.yaml`
  - `values.yaml`
  - `templates/_helpers.tpl`
  - `templates/deployment.yaml`
  - `templates/service.yaml`
  - `README.md`
- Kept the chart minimal and values-driven with simple labels, image settings, service settings, and container port configuration.

## What I tested
- Confirmed the scaffold did not exist before writing it.
- Verified all requested files exist.
- Verified the expected scaffold strings with `rg`.
- Ran Helm validation successfully:
  - `helm lint scaffolds/helm`
  - `helm template test-release scaffolds/helm`

## Files changed
- `scaffolds/helm/Chart.yaml`
- `scaffolds/helm/values.yaml`
- `scaffolds/helm/templates/_helpers.tpl`
- `scaffolds/helm/templates/deployment.yaml`
- `scaffolds/helm/templates/service.yaml`
- `scaffolds/helm/README.md`

## Self-review findings
- The scaffold matches the brief and stays intentionally small.
- The chart renders cleanly with Helm.
- The README keeps instructions short and actionable.

## Issues or concerns
- None.

#!/usr/bin/env bash
set -euo pipefail

cd "{{ .inputs.RepoName }}"
if [ -d scaffolds/helm ]; then
  rsync -a --exclude 'README.md' scaffolds/helm/ ./
  mkdir -p docs
  cp scaffolds/helm/README.md docs/HELM-SCAFFOLD.md
  helm lint .
  helm template test-release .
  rm -rf scaffolds/helm scaffolds/terraform-module
else
  echo 'Helm scaffold is not available in this checkout yet.'
  exit 1
fi

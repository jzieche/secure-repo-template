#!/usr/bin/env bash
set -euo pipefail

cd "{{ .inputs.RepoName }}"
if [ -d scaffolds/terraform-module ]; then
  rsync -a --exclude 'README.md' scaffolds/terraform-module/ ./
  mkdir -p docs
  cp scaffolds/terraform-module/README.md docs/TERRAFORM-MODULE-SCAFFOLD.md
  terraform fmt -check
  terraform init -backend=false
  terraform validate
  rm -rf scaffolds/helm scaffolds/terraform-module
else
  echo 'Terraform module scaffold is not available in this checkout yet.'
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

cd "{{ .inputs.RepoName }}"
./init.sh
./scripts/verify-security.sh

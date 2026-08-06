#!/usr/bin/env bash
set -euo pipefail

cd "${REPO_FILES:?REPO_FILES is not set}"
./init.sh
./scripts/verify-security.sh

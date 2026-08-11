#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1083
gh repo create "{{ .inputs.OrgName }}/{{ .inputs.RepoName }}" --template "{{ .inputs.TemplateOwner }}/secure-repo-template" --{{ .inputs.Visibility }}

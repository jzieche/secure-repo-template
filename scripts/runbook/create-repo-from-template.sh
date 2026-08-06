#!/usr/bin/env bash
set -euo pipefail

gh repo create "{{ .inputs.OrgName }}/{{ .inputs.RepoName }}" --template "{{ .inputs.TemplateOwner }}/secure-repo-template" --{{ .inputs.Visibility }}

#!/usr/bin/env bash
set -u

# Main initialization script for repository setup
# Phases: environment check, checkpoint resume, configuration gathering, summary, dry-run preview

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/init-utils.sh
source "${script_dir}/scripts/lib/init-utils.sh"

# =============================================================================
# Phase 1: Header and Environment Check
# =============================================================================
init_log "Starting repository initialization..."

# Check for required commands
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    init_error "Required command '$cmd' not found. Please install it and try again."
    return 1
  fi
}

init_log "Checking for required commands..."
if ! require_command "gh"; then
  exit 1
fi
if ! require_command "python"; then
  exit 1
fi
init_log "All required commands found"

# =============================================================================
# Phase 2: Checkpoint Resume Logic
# =============================================================================
if checkpoint_exists; then
  init_log "Checkpoint found from previous initialization"
  checkpoint_data=$(load_checkpoint)
  
  resume_choice=$(prompt_user "Resume initialization from checkpoint?" "y")
  
  if [[ "$resume_choice" == "y" || "$resume_choice" == "Y" ]]; then
    init_log "Resuming from checkpoint..."
    
    # Extract variables from checkpoint using Python
    github_repo=$(printf '%s' "$checkpoint_data" | python -c "import json, sys; data=json.load(sys.stdin); print(data.get('variables', {}).get('github_repo', ''))")
    release_team=$(printf '%s' "$checkpoint_data" | python -c "import json, sys; data=json.load(sys.stdin); print(data.get('variables', {}).get('release_team', ''))")
    production_reviewers=$(printf '%s' "$checkpoint_data" | python -c "import json, sys; data=json.load(sys.stdin); print(data.get('variables', {}).get('production_reviewers', ''))")
    production_wait=$(printf '%s' "$checkpoint_data" | python -c "import json, sys; data=json.load(sys.stdin); print(data.get('variables', {}).get('production_wait', ''))")
    required_checks=$(printf '%s' "$checkpoint_data" | python -c "import json, sys; data=json.load(sys.stdin); print(data.get('variables', {}).get('required_checks', ''))")
    
    init_log "Checkpoint variables loaded"
  else
    init_log "Starting fresh initialization..."
    rm -f .init-state.json
    github_repo=""
    release_team=""
    production_reviewers=""
    production_wait=""
    required_checks=""
  fi
else
  init_log "No checkpoint found, starting fresh initialization"
  github_repo=""
  release_team=""
  production_reviewers=""
  production_wait=""
  required_checks=""
fi

# =============================================================================
# Phase 3: Configuration Gathering
# =============================================================================
init_log "Gathering configuration..."

# Detect GitHub repository
if [[ -z "$github_repo" ]]; then
  init_log "Auto-detecting GitHub repository..."
  if ! github_repo=$(detect_github_repo); then
    init_error "Failed to detect GitHub repository. Make sure you are in a GitHub repository or authenticated with 'gh auth login'"
    exit 1
  fi
  init_log "Detected repository: $github_repo"
else
  init_log "Using cached repository: $github_repo"
fi

# Prompt for RELEASE_TEAM_SLUG
if [[ -z "$release_team" ]]; then
  release_team=$(prompt_user "Release team slug" "release-team")
  init_log "Release team slug: $release_team"
else
  init_log "Using cached release team slug: $release_team"
fi

# Prompt for PRODUCTION_REVIEWERS as JSON
if [[ -z "$production_reviewers" ]]; then
  # Build smart default based on team slug
  smart_default="{\"team\": \"$release_team\"}"
  
  production_reviewers=$(prompt_user "Production reviewers (JSON)" "$smart_default")
  
  # Validate production reviewers JSON
  if ! validate_json "$production_reviewers"; then
    init_error "Invalid JSON for production reviewers"
    exit 1
  fi
  init_log "Production reviewers: $production_reviewers"
else
  init_log "Using cached production reviewers: $production_reviewers"
fi

# Prompt for PRODUCTION_WAIT_TIMER_MINUTES
if [[ -z "$production_wait" ]]; then
  production_wait=$(prompt_user "Production wait timer (minutes)" "10")
  init_log "Production wait timer: $production_wait minutes"
else
  init_log "Using cached production wait timer: $production_wait"
fi

# Prompt for REQUIRED_CHECKS (comma-separated)
if [[ -z "$required_checks" ]]; then
  required_checks=$(prompt_user "Required checks (comma-separated)" "CodeQL,Dependency Review")
  init_log "Required checks: $required_checks"
else
  init_log "Using cached required checks: $required_checks"
fi

# =============================================================================
# Phase 4: Configuration Summary and Confirmation
# =============================================================================
init_log "Preparing configuration summary..."

# Build config JSON with all values
config_json=$(python -c "
import json
config = {
  'github_repo': '$github_repo',
  'release_team': '$release_team',
  'production_reviewers': json.loads('$production_reviewers'),
  'production_wait': '$production_wait',
  'required_checks': '$required_checks'
}
print(json.dumps(config))
")

# Display summary
if ! show_summary "$config_json"; then
  exit 1
fi

# Ask user to proceed
proceed=$(prompt_user "Proceed with initialization?" "y")

if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
  init_log "User canceled initialization"
  exit 2
fi

# Save checkpoint after confirmation
if ! save_checkpoint "config_gathered" "$config_json"; then
  init_error "Failed to save checkpoint"
  exit 1
fi

# =============================================================================
# Phase 5: Dry-run Preview Option
# =============================================================================
dry_run_choice=$(prompt_user "Preview changes without applying?" "n")

if [[ "$dry_run_choice" == "y" || "$dry_run_choice" == "Y" ]]; then
  export DRY_RUN=1
  init_log "DRY_RUN mode enabled"
else
  export DRY_RUN=0
fi

# =============================================================================
# Export configuration variables for downstream scripts
# =============================================================================
export GITHUB_REPOSITORY="$github_repo"
export RELEASE_TEAM_SLUG="$release_team"
export PRODUCTION_REVIEWERS="$production_reviewers"
export PRODUCTION_WAIT_TIMER_MINUTES="$production_wait"
export REQUIRED_CHECKS="$required_checks"

init_log "Configuration gathered successfully"

# =============================================================================
# Phase 6: Bootstrap Execution Phase
# =============================================================================
init_log "=== Starting Bootstrap Phase ==="

# Environment variables are already exported above, verify they're set
init_log "Running bootstrap-security.sh..."

if ! "${script_dir}/scripts/bootstrap-security.sh"; then
  init_error "Bootstrap failed. Checkpoint saved for resume."
  exit 1
fi

init_log "Bootstrap completed successfully."

# Save checkpoint after successful bootstrap
config_json=$(python -c "
import json
config = {
  'github_repo': '$github_repo',
  'release_team': '$release_team',
  'production_reviewers': json.loads('$production_reviewers'),
  'production_wait': '$production_wait',
  'required_checks': '$required_checks'
}
print(json.dumps(config))
")

if ! save_checkpoint "bootstrap_complete" "$config_json"; then
  init_error "Failed to save bootstrap checkpoint"
  exit 1
fi

# =============================================================================
# Phase 7: Template Cleanup Phase
# =============================================================================
init_log "=== Cleaning Up Template Artifacts ==="

cleanup_template_files

if ! save_checkpoint "templates_cleaned" "$config_json"; then
  init_error "Failed to save templates cleanup checkpoint"
  exit 1
fi

# =============================================================================
# Phase 8: Init Script Removal Phase (Optional)
# =============================================================================
remove_init_choice=$(prompt_user "Remove init.sh from repository?" "n")

keep_init="false"
if [[ "$remove_init_choice" != "y" && "$remove_init_choice" != "Y" ]]; then
  keep_init="true"
fi

cleanup_init_artifacts "$keep_init"

# =============================================================================
# Phase 9: Completion Message
# =============================================================================
init_log "✓ Repository initialization complete!"

init_log "Next steps:"
init_log "  1. Review branch protection rules and rulesets: gh repo view --web"
init_log "  2. Run verify-security.sh to confirm settings: scripts/verify-security.sh"
init_log "  3. Customize README.md for your project"
init_log "  4. Set up your development workflow per docs/BRANCH-NAMING.md"

exit 0

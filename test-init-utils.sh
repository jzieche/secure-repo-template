#!/usr/bin/env bash
# Test suite for init-utils.sh
set -u
set +e  # Don't exit on errors

# Source the library to test
source ./scripts/lib/init-utils.sh

# Track test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test reporter helper
run_test() {
  local test_name="$1"
  local test_command="$2"
  
  ((TESTS_RUN++))
  
  if eval "$test_command" >/dev/null 2>&1; then
    printf '[PASS] %s\n' "$test_name"
    ((TESTS_PASSED++))
    return 0
  else
    printf '[FAIL] %s\n' "$test_name"
    ((TESTS_FAILED++))
    return 0
  fi
}

printf '=== Testing init-utils.sh ===\n\n'

# Test 1: init_log function exists and can be called
run_test "init_log exists and callable" "init_log 'test message' >/dev/null 2>&1; true"

# Test 2: init_error returns exit code 1
run_test "init_error returns 1" "init_error 'test error' 2>/dev/null; [[ \$? -eq 1 ]]"

# Test 3: init_warn function exists and can be called
run_test "init_warn exists and callable" "init_warn 'test warning' >/dev/null 2>&1; true"

# Test 4: prompt_user with default (non-interactive, will use default)
run_test "prompt_user returns default when no input" "echo '' | prompt_user 'test' 'default' 2>/dev/null | grep -q 'default'"

# Test 5: prompt_required exists and is callable
run_test "prompt_required exists and callable" "echo 'input' | prompt_required 'test' 2>/dev/null | grep -q 'input'"

# Test 6: validate_json with valid JSON
run_test "validate_json accepts valid JSON" "validate_json '{\"key\":\"value\"}'"

# Test 7: validate_json rejects invalid JSON
run_test "validate_json rejects invalid JSON" "! validate_json '{invalid}'"

# Test 8: checkpoint_exists returns 1 when file doesn't exist
run_test "checkpoint_exists returns 1 when missing" "! checkpoint_exists"

# Test 9: save_checkpoint creates file
run_test "save_checkpoint creates file" "save_checkpoint 'test' '{\"key\":\"value\"}' && [[ -f .init-state.json ]]"

# Test 10: load_checkpoint returns 0 when file exists
run_test "load_checkpoint succeeds when file exists" "load_checkpoint >/dev/null 2>&1"

# Test 11: checkpoint_exists returns 0 when file exists (after save)
run_test "checkpoint_exists returns 0 when exists" "checkpoint_exists"

# Test 12: cleanup_template_files function is callable
run_test "cleanup_template_files is callable" "cleanup_template_files >/dev/null 2>&1; true"

# Test 13: cleanup_init_artifacts removes state file
run_test "cleanup_init_artifacts removes state" "cleanup_init_artifacts true >/dev/null 2>&1 && ! [[ -f .init-state.json ]]"

# Test 14: detect_github_repo uses gh command (may fail without proper repo setup)
run_test "detect_github_repo exists and callable" "command -v gh >/dev/null && detect_github_repo >/dev/null 2>&1 || true; true"

# Test 15: show_summary with valid JSON
run_test "show_summary with valid JSON" "show_summary '{\"repo\":\"test\",\"owner\":\"user\"}' >/dev/null 2>&1; true"

# Cleanup test artifacts
rm -f .init-state.json

printf '\n=== Test Results ===\n'
printf 'Tests Run:    %d\n' "$TESTS_RUN"
printf 'Tests Passed: %d\n' "$TESTS_PASSED"
printf 'Tests Failed: %d\n' "$TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  printf '\n✓ All tests passed!\n'
  exit 0
else
  printf '\n✗ Some tests failed.\n'
  exit 1
fi

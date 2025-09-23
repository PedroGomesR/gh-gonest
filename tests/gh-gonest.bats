#!/usr/bin/env bats

setup() {
    # Set the entrypoint script path
    SCRIPT_PATH="$BATS_TEST_DIRNAME/../gh-gonest"

    # Extract version from script once for all tests
    EXPECTED_VERSION=$(grep '^readonly VERSION=' "$SCRIPT_PATH" | cut -d'"' -f2)

    # Add mock gh to PATH for integration tests
    export PATH="$BATS_TEST_DIRNAME/bin:$PATH"
}

teardown() {
    # Clean up environment variables used in integration tests
    unset GH_AUTH_EXIT GH_NOTIFICATIONS GH_API_EXIT
}

###############################################################################
# Script Existence & Basic Setup
###############################################################################

@test "check for script existence and executability" {
    [ -x "$SCRIPT_PATH" ]
}

###############################################################################
# Help & Version Information
###############################################################################

@test "check for help flag displaying usage information" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gh-gonest" ]]
    [[ "$output" =~ "--after" ]]
    [[ "$output" =~ "--before" ]]
    [[ "$output" =~ "--dry-run" ]]
}

@test "check for short help flag displaying usage information" {
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gh-gonest" ]]
    [[ "$output" =~ "--after" ]]
    [[ "$output" =~ "--before" ]]
    [[ "$output" =~ "--dry-run" ]]
}

@test "check for version flag displaying version information" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gh-gonest $EXPECTED_VERSION" ]]
}

@test "check for short version flag displaying version information" {
    run "$SCRIPT_PATH" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gh-gonest $EXPECTED_VERSION" ]]
}

###############################################################################
# Authentication & External Dependencies
###############################################################################

@test "check for authentication failure handling" {
    export GH_AUTH_EXIT=1

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not authenticated" ]]
}

@test "check for missing GitHub CLI detection" {
     # Override the command builtin to make 'command -v gh' fail
    run bash -c '
        command() {
            if [[ "$1" == "-v" && "$2" == "gh" ]]; then
                return 1
            else
                builtin command "$@"
            fi
        }
        export -f command
        '"$SCRIPT_PATH"' --dry-run
    '

    [ "$status" -eq 1 ]
    [[ "$output" =~ "GitHub CLI (gh) is not installed" ]]
}

@test "check for missing jq detection" {
    # Override the command builtin to make 'command -v jq' fail
    run bash -c '
        command() {
            if [[ "$1" == "-v" && "$2" == "jq" ]]; then
                return 1
            else
                builtin command "$@"
            fi
        }
        export -f command
        '"$SCRIPT_PATH"' --dry-run
    '

    [ "$status" -eq 1 ]
    [[ "$output" =~ "jq is required but not installed" ]]
}

###############################################################################
# Command Line Argument Validation
###############################################################################

@test "check for invalid after timestamp format rejection" {
    run "$SCRIPT_PATH" --after "invalid-date"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid --after timestamp format" ]]
}

@test "check for missing after timestamp argument rejection" {
    run "$SCRIPT_PATH" --after
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Option --after requires a timestamp" ]]
}

@test "check for invalid before timestamp format rejection" {
    run "$SCRIPT_PATH" --before "invalid-date"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid --before timestamp format" ]]
}

@test "check for missing before timestamp argument rejection" {
    run "$SCRIPT_PATH" --before
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Option --before requires a timestamp" ]]
}

@test "check for unknown option error handling" {
    run "$SCRIPT_PATH" --unknown-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

###############################################################################
# Core Functionality & Integration - Failure Cases
###############################################################################

@test "check for empty notification feed handling" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/empty.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No notifications found" ]]
}

@test "check for malformed JSON handling in notifications endpoint" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/wrong-structure.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to extract notification details from response" ]]
}

@test "check for JSON counting failure in notifications response" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/malformed.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to count notifications in response" ]]
}

@test "check for parameterized API failure handling in dry-run mode" {
    export GH_AUTH_EXIT=0
    export GH_API_EXIT=1
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/with-phantoms.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to fetch notifications from GitHub API" ]]
}

@test "check for parameterized API failure handling in dry-run mode with parameters" {
    export GH_AUTH_EXIT=0
    export GH_API_EXIT=1
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/with-phantoms.json"

    run "$SCRIPT_PATH" --after "2025-01-01T00:00:00Z" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to fetch notifications with parameters from GitHub API" ]]
}

@test "check for date filtering failure handling in dry-run mode" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/malformed.json"

    run "$SCRIPT_PATH" --before "2025-12-31T23:59:59Z" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to filter notifications by date" ]]
}

@test "check for notification cleanup failure (mark as read fails)" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/with-phantoms.json"
    export GH_API_PATCH_EXIT=1

    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to mark as read: phantom/repo. Skipping..." ]]
    [[ "$output" =~ "Summary: Cleaned 0, failed 1" ]]
}

@test "check for notification cleanup failure (mark as done fails)" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/with-phantoms.json"
    export GH_API_DELETE_EXIT=1

    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to mark as done: phantom/repo. Skipping..." ]]
    [[ "$output" =~ "Summary: Cleaned 0, failed 1" ]]
}

@test "check unsubscribe with null subscription URL" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/phantom-null-subscription.json"
    export GONEST_DEBUG=1
    run "$SCRIPT_PATH"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "No valid subscription URL to unsubscribe from" ]]
    [[ "$output" =~ "Summary: Cleaned 0, failed 1" ]]
}

@test "check unsubscribe with empty subscription URL" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/phantom-empty-subscription.json"
    export GONEST_DEBUG=1

    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No valid subscription URL to unsubscribe from" ]]
    [[ "$output" =~ "Summary: Cleaned 0, failed 1" ]]
}

@test "check unsubscribe with invalid subscription URL format" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/phantom-invalid-subscription.json"
    export GONEST_DEBUG=1

    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No valid subscription URL to unsubscribe from" ]]
    [[ "$output" =~ "Summary: Cleaned 0, failed 1" ]]
}

@test "check unsubscribe failure handling" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/phantom-with-subscription.json"
    export GONEST_DEBUG=1
    export GH_API_SUBSCRIPTION_DELETE_EXIT=1

    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to unsubscribe from:" ]]
    [[ "$output" =~ "Summary: Cleaned 0, failed 1" ]]
}

###############################################################################
# Core Functionality & Integration - Successful Cases
###############################################################################

@test "check for no phantom notifications found message" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/no-phantoms.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No phantom notifications found - all clean!" ]]
}

@test "check for phantom notification detection in dry-run mode" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/with-phantoms.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found phantom: phantom/repo - Issue: Issue" ]]
    [[ "$output" =~ "Found 1 phantom notification(s)" ]]
    [[ "$output" =~ "Would clean 1 phantom notification(s) - run without --dry-run" ]]
}

@test "check for multiple phantom notifications handling in dry-run mode" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/multiple-phantoms.json"

    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found phantom: deleted/repo1 - Issue: Spam Issue 1" ]]
    [[ "$output" =~ "Found phantom: deleted/repo2 - Issue: Spam Issue 2" ]]
    [[ "$output" =~ "Found phantom: phantom/repo - Issue: Another phantom" ]]
    [[ "$output" =~ "Found 3 phantom notification(s)" ]]
    [[ "$output" =~ "Would clean 3 phantom notification(s) - run without --dry-run for cleanup" ]]
}

@test "check successful notification cleanup" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/phantom-with-subscription.json"
    export GH_API_PATCH_EXIT=0
    export GH_API_DELETE_EXIT=0
    export GH_API_SUBSCRIPTION_DELETE_EXIT=0

    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found phantom: phantom/repo" ]]
    [[ "$output" =~ "Cleaning phantom notifications" ]]
    [[ "$output" =~ "Cleaned: phantom/repo" ]]
    [[ "$output" =~ "Cleanup complete!" ]]
    [[ "$output" =~ "Summary: Successfully cleaned 1" ]]
}

@test "check successful cleanup with mixed valid and phantom notifications" {
    export GH_AUTH_EXIT=0
    export GH_NOTIFICATIONS="$BATS_TEST_DIRNAME/data/mixed-notifications.json"
    export GH_API_PATCH_EXIT=0
    export GH_API_DELETE_EXIT=0
    export GH_API_SUBSCRIPTION_DELETE_EXIT=0

    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]

    # Check that it found the correct number of total notifications
    [[ "$output" =~ "Found 8 total notifications" ]]

    # Check that it identified phantom notifications correctly (5 phantoms)
    [[ "$output" =~ "Found phantom: phantom/repo1 - Issue: Ghost Issue 1" ]]
    [[ "$output" =~ "Found phantom: deleted/repo2 - PullRequest: Ghost PR 1" ]]
    [[ "$output" =~ "Found phantom: phantom/repo3 - Discussion: Phantom Discussion" ]]
    [[ "$output" =~ "Found phantom: ghost/repo4 - Release: Deleted Release" ]]
    [[ "$output" =~ "Found phantom: phantom/repo5 - Issue: Ghost Issue 2" ]]

    # Check summary shows 5 phantoms found
    [[ "$output" =~ "Found 5 phantom notification(s)" ]]

    # Check that it did not identify valid notifications as phantoms
    [[ ! "$output" =~ "Found phantom: valid/repo1" ]]
    [[ ! "$output" =~ "Found phantom: valid/repo2" ]]
    [[ ! "$output" =~ "Found phantom: valid/repo3" ]]

    # Check cleanup process
    [[ "$output" =~ "Cleaning phantom notifications" ]]
    [[ "$output" =~ "Cleaned: phantom/repo1" ]]
    [[ "$output" =~ "Cleaned: deleted/repo2" ]]
    [[ "$output" =~ "Cleaned: phantom/repo3" ]]
    [[ "$output" =~ "Cleaned: ghost/repo4" ]]
    [[ "$output" =~ "Cleaned: phantom/repo5" ]]

    # Check final summary
    [[ "$output" =~ "Cleanup complete!" ]]
    [[ "$output" =~ "Summary: Successfully cleaned 5" ]]
    [[ "$output" =~ "Execution completed successfully" ]]
}

#!/usr/bin/env bash
###############################################################################
# Coverage runner for gh-gonest tests
###############################################################################

set -e

# Create coverage output directory
COVERAGE_DIR="tests/coverage"
mkdir -p "$COVERAGE_DIR"

# Clean previous coverage data
rm -rf "${COVERAGE_DIR:?}"/*

echo "Running tests with coverage analysis..."

# Run BATS tests through kcov
kcov \
    --exclude-pattern=/usr,/tmp \
    --include-pattern="$(pwd)/gh-gonest" \
    "$COVERAGE_DIR" \
    bats tests/gh-gonest.bats

echo ""
echo "Coverage report generated in: $COVERAGE_DIR"
echo "Open $COVERAGE_DIR/index.html in a browser to view the report"


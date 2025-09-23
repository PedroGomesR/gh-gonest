###############################################################################
# Makefile for gh-gonest GitHub CLI extension
###############################################################################

.PHONY: help setup test

# Default target
help:
	@echo "Available targets:"
	@echo "  clean      - Clean temporary files"
	@echo "  setup      - Install development dependencies"
	@echo "  test       - Run BATS tests"

# Setup development dependencies
setup:
	@echo "Installing test dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install bats-core; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats; \
	else \
		echo "Please install bats, shellcheck, and kcov manually:"; \
		echo "  - BATS: https://bats-core.readthedocs.io/"; \
	fi

# Run all tests
test:
	@echo "Running BATS tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/gh-gonest.bats; \
	else \
		echo "BATS not installed. Run 'make setup' to install dependencies"; \
		exit 1; \
	fi

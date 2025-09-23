###############################################################################
# Makefile for gh-gonest GitHub CLI extension
###############################################################################

.PHONY: help lint setup test

# Default target
help:
	@echo "Available targets:"
	@echo "  help       - Show this help and exit"
	@echo "  lint       - Run shellcheck linting"
	@echo "  setup      - Install development dependencies"
	@echo "  test       - Run BATS tests"

# Lint bash scripts
lint:
	@echo "Linting bash scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck gh-gonest; \
		shellcheck tests/bin/gh; \
		echo "Linting passed"; \
	else \
		echo "shellcheck is not installed. Run 'make setup' to install dependencies"; \
	fi

# Setup development dependencies
setup:
	@echo "Installing test dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install bats-core shellcheck; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats shellcheck; \
	else \
		echo "Please install bats, shellcheck, and kcov manually:"; \
		echo "  - BATS: https://bats-core.readthedocs.io/"; \
		echo "  - shellcheck: https://github.com/koalaman/shellcheck"; \
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

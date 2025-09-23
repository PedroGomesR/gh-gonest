###############################################################################
# Makefile for gh-gonest GitHub CLI extension
###############################################################################

.PHONY: clean coverage help install lint setup test

# Default target
help:
	@echo "Available targets:"
	@echo "  clean      - Clean temporary files"
	@echo "  coverage   - Run tests with coverage analysis"
	@echo "  help       - Show this help message and exit"
	@echo "  install    - Install as gh extension locally"
	@echo "  lint       - Run shellcheck linting"
	@echo "  setup      - Install development dependencies"
	@echo "  test       - Run BATS tests"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -rf tests/coverage

# Run tests with coverage analysis
coverage:
	@echo "Starting coverage analysis..."
	@./tests/coverage.sh

# Install locally for testing
install:
	@echo "Installing gh-gonest locally..."
	gh extension install .

# Lint bash scripts
lint:
	@echo "Linting bash scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck gh-gonest; \
		shellcheck tests/coverage.sh; \
		shellcheck tests/bin/gh; \
		echo "Linting passed"; \
	else \
		echo "shellcheck is not installed. Run 'make setup' to install dependencies"; \
	fi

# Setup development dependencies
setup:
	@echo "Installing test dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install bats-core kcov shellcheck; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats kcov shellcheck; \
	else \
		echo "Please install bats, shellcheck, and kcov manually:"; \
		echo "  - BATS: https://bats-core.readthedocs.io/"; \
		echo "  - kcov: https://github.com/SimonKagstrom/kcov"; \
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

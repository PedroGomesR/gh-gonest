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

# Install BATS testing framework
install_bats:
	@echo "Installing BATS..."
	@cd /tmp && git clone https://github.com/bats-core/bats-core.git && \
	cd bats-core && sudo ./install.sh /usr/local && cd /tmp && rm -rf bats-core

# Install kcov coverage tool
install_kcov:
	@echo "Installing kcov..."
	@sudo apt-get install -y cmake g++ libdw-dev libelf-dev libcurl4-openssl-dev
	@cd /tmp && git clone https://github.com/SimonKagstrom/kcov.git && \
	cd kcov && mkdir build && cd build && cmake .. && make && sudo make install && cd /tmp && rm -rf kcov

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
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck; \
		$(MAKE) install_bats; \
		$(MAKE) install_kcov; \
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

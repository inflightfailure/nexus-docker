#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

set_strict_mode
setup_error_handling

print_section "Nexus Repository Test Suite"
print_info "Running comprehensive tests for all repository types..."

# Make scripts executable
chmod +x test-repos.sh test-docker.sh test-pypi.sh

# Run basic repository tests
print_info "1. Running basic repository tests..."
./test-repos.sh

# Run Docker-specific tests
print_info "2. Running Docker registry tests..."
./test-docker.sh

# Run PyPI-specific tests
print_info "3. Running PyPI repository tests..."
./test-pypi.sh

print_section "All Tests Completed"

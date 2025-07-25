#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043
# Script to run pre-commit checks manually

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../nexus-docker/scripts/common.sh"

set_strict_mode
setup_error_handling

print_section "🔍 Running pre-commit checks"

# Check if we're in the project root
if ! check_file "Pipfile" "Pipfile"; then
    print_status "Error: Pipfile not found. Please run this script from the project root." 1
    exit 1
fi

print_info "Using pipenv virtual environment..."
if pipenv run pre-commit run --all-files; then
    print_status "All pre-commit checks passed!" 0
    exit 0
else
    print_status "Some pre-commit checks failed." 1
    print_info "Run 'pipenv run pre-commit run --all-files' to see detailed output."
    print_info "Many issues can be auto-fixed by running the command again."
    exit 1
fi

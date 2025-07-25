#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043
# Development environment setup script

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../nexus-docker/scripts/common.sh"

set_strict_mode
setup_error_handling

echo -e "${BLUE}🚀 Setting up development environment...${NC}"

# Check if pipenv is installed
if ! command -v pipenv >/dev/null 2>&1; then
    print_info "⚠ pipenv not found. Installing pipenv..."
    pip3 install pipenv
fi

# Install development dependencies
print_section "📦 Installing development dependencies"
if pipenv install --dev; then
    print_status "Dependencies installed successfully" 0
else
    print_status "Failed to install dependencies" 1
    exit 1
fi

# Setup pre-commit hooks
print_section "🔧 Setting up pre-commit hooks"
if pipenv run pre-commit install && pipenv run pre-commit install --hook-type commit-msg; then
    print_status "Pre-commit hooks installed" 0
else
    print_status "Failed to install pre-commit hooks" 1
    exit 1
fi

# Create secrets baseline
print_section "🔒 Creating secrets baseline"
if pipenv run detect-secrets scan . > .secrets.baseline; then
    print_status "Secrets baseline created" 0
else
    print_status "Failed to create secrets baseline" 1
    exit 1
fi

# Run initial checks
print_section "🔍 Running initial pre-commit checks"
if pipenv run pre-commit run --all-files; then
    print_status "All pre-commit checks passed" 0
else
    print_info "⚠ Some checks failed initially (this is normal for first run)"
fi

print_section "✅ Development environment setup complete"
print_info "You can now run:"
print_info "• make lint - Run linting and security checks"
print_info "• pipenv shell - Activate the virtual environment"
print_info "• pipenv run pre-commit run --all-files - Run all checks"

#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043
# shellcheck disable=SC2181,SC2155,SC2086,SC1090
# Common functions and variables for Nexus Docker scripts

# Set strict error handling (can be sourced by other scripts)
set_strict_mode() {
    set -e  # Exit on any error
    set -u  # Exit on undefined variables
    set -o pipefail  # Exit on pipe failures
}

# Configuration
NEXUS_URL="http://localhost:8081"
DOCKER_REGISTRY="localhost:8082"
NEXUS_USER="admin"
CREDENTIALS_FILE="../.nexus-credentials"

# Colors for output (shared across all scripts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters for test results (can be used by test scripts)
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to print status messages
print_status() {
    local message="$1"
    local exit_code=$2

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $message${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $message${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to print skip status
print_skip() {
    echo -e "${YELLOW}⚠ $1${NC}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# Function to print info messages
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Function to print section headers
print_section() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Function to generate secure password (reusable across scripts)
generate_password() {
    # Generate a 16-character password with mixed case, numbers, and symbols
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-16
}

# Function to check dependencies
check_dependency() {
    local cmd="$1"
    local name="${2:-$1}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_status "❌ Error: $name is required but not installed" 1
        echo "Please install $name and try again"
        return 1
    fi
    return 0
}

# Function to check multiple dependencies
check_dependencies() {
    local deps=("$@")
    local failed=0

    for dep in "${deps[@]}"; do
        if ! check_dependency "$dep"; then
            failed=1
        fi
    done

    return $failed
}

# Function to setup error handling
setup_error_handling() {
    trap 'echo -e "\n${RED}❌ Script failed at line $LINENO${NC}" >&2' ERR
}

# Function to load credentials safely
load_credentials() {
    # Try to load from credentials file first
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        source "$CREDENTIALS_FILE"
        if [[ -n "$NEXUS_ADMIN_PASSWORD" ]]; then
            print_info "Using credentials from $CREDENTIALS_FILE"
            return 0
        fi
    fi

    # Try to get password from container (fallback for compatibility)
    if docker ps --format "{{.Names}}" | grep -q "^nexus$"; then
        local container_password
        if container_password=$(docker exec nexus cat /nexus-data/admin.password 2>/dev/null); then
            NEXUS_ADMIN_PASSWORD="$container_password"
            print_info "Retrieved password from Nexus container"
            return 0
        fi
    fi

    # Final fallback - but warn about security risk
    print_status "WARNING: No secure credentials found. This is a security risk!" 1
    echo -e "${RED}Please run: ../scripts/generate-credentials.sh${NC}"
    echo -e "${YELLOW}For now, trying default password (INSECURE!)${NC}"
    NEXUS_ADMIN_PASSWORD="admin123"  # pragma: allowlist secret
    return 1
}

# Function to get admin password (updated)
get_admin_password() {
    load_credentials
    echo "$NEXUS_ADMIN_PASSWORD"
}

# Function to test Nexus API connectivity
test_nexus_connectivity() {
    local admin_password="$1"

    echo "Testing Nexus API connectivity..."
    if curl -s -u $NEXUS_USER:"$admin_password" -f "$NEXUS_URL"/service/rest/v1/status > /dev/null; then
        print_status "Nexus API connectivity" 0
        return 0
    else
        print_status "Nexus API connectivity" 1
        return 1
    fi
}

# Function to check if Nexus container is running
check_nexus_container() {
    if docker ps --format "table {{.Names}}" | grep -q "nexus"; then
        print_status "Nexus container is running" 0
        return 0
    else
        print_status "Nexus container is not running" 1
        echo "Please start Nexus with: docker-compose up -d"
        return 1
    fi
}

# Function to wait for Nexus to be ready
wait_for_nexus() {
    local max_attempts=30
    local attempt=1
    local admin_password="$1"

    print_info "Waiting for Nexus to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if curl -s -u $NEXUS_USER:"$admin_password" -f "$NEXUS_URL"/service/rest/v1/status > /dev/null 2>&1; then
            print_status "Nexus is ready (attempt $attempt/$max_attempts)" 0
            return 0
        else
            echo -n "."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done

    echo ""
    print_status "Nexus failed to become ready after $max_attempts attempts" 1
    return 1
}

# Function to check EULA status
check_eula_status() {
    local admin_password="$1"
    local response

    response=$(curl -s -u "$NEXUS_USER":"$admin_password" "$NEXUS_URL/service/rest/v1/system/eula" 2>/dev/null)

    if echo "$response" | grep -q '"accepted":true'; then
        return 0  # EULA accepted
    else
        return 1  # EULA not accepted
    fi
}

# Function to print test summary
print_test_summary() {
    echo -e "\n${GREEN}=== Test Summary ===${NC}"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Tests skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo ""
    echo "Access Nexus UI at: $NEXUS_URL"
    echo "Docker registry at: $DOCKER_REGISTRY"
}

# Function to create temporary directory for tests
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d)
    echo "$temp_dir"
}

# Function to cleanup temporary directory
cleanup_temp_dir() {
    local temp_dir="$1"
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Function to backup file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup}"

    if [[ -f "$file" ]]; then
        cp "$file" "${file}${backup_suffix}"
        print_info "Backed up $file to ${file}${backup_suffix}"
        return 0
    fi
    return 1
}

# Function to create secure file with proper permissions
create_secure_file() {
    local file="$1"
    local content="$2"
    local permissions="${3:-600}"

    echo "$content" > "$file"
    chmod "$permissions" "$file"
    print_info "Created secure file: $file (permissions: $permissions)"
}

# Function to check if file exists and is readable
check_file() {
    local file="$1"
    local description="${2:-$file}"

    if [[ -f "$file" && -r "$file" ]]; then
        print_status "$description exists and is readable" 0
        return 0
    else
        print_status "$description missing or not readable" 1
        return 1
    fi
}

# Function to validate environment variable
validate_env_var() {
    local var_name="$1"
    local description="${2:-$var_name}"

    if [[ -n "${!var_name:-}" ]]; then
        print_status "$description is set" 0
        return 0
    else
        print_status "$description is not set" 1
        return 1
    fi
}

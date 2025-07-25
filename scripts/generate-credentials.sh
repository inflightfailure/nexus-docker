#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043
# Secure credential management for Nexus Docker setup

# This script generates secure random passwords and manages credentials safely
# It should be run BEFORE starting the Nexus container

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../nexus-docker/scripts/common.sh"

set_strict_mode
setup_error_handling

CREDENTIALS_FILE="./.nexus-credentials"
ENV_FILE="./.env"

echo -e "${BLUE}🔐 Nexus Security Setup${NC}"

# Function to create credentials file
create_credentials() {
    local admin_password="$1"

    local cred_content="# Nexus Credentials - DO NOT COMMIT TO VERSION CONTROL
# Generated on: $(date)
NEXUS_ADMIN_USERNAME=admin
NEXUS_ADMIN_PASSWORD=$admin_password

# Database credentials
POSTGRES_PASSWORD=$(generate_password)
POSTGRES_USER=nexus
POSTGRES_DB=nexus"

    create_secure_file "$CREDENTIALS_FILE" "$cred_content"
    print_status "Credentials file created: $CREDENTIALS_FILE" 0
    print_info "⚠ This file contains sensitive information and should not be committed to version control"
}

# Function to create/update .env file
create_env_file() {
    if [[ -f "$ENV_FILE" ]]; then
        print_info "⚠ .env file already exists, backing up to .env.backup"
        backup_file "$ENV_FILE"
    fi

    # Source the credentials
    source "$CREDENTIALS_FILE"

    # Check if .env.example exists and offer to use it as base
    local env_example="./nexus-docker/.env.example"
    if [[ -f "$env_example" ]]; then
        print_info "Found .env.example template"
        read -p "Do you want to use .env.example as base template? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            # Copy .env.example and replace sensitive values
            cp "$env_example" "$ENV_FILE"

            # Replace insecure default passwords with secure ones
            sed -i "s/POSTGRES_PASSWORD=nexus123/POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/" "$ENV_FILE"
            sed -i "s/ADMIN_PASSWORD=admin123/NEXUS_ADMIN_PASSWORD=${NEXUS_ADMIN_PASSWORD}/" "$ENV_FILE"

            # Add admin username if not present
            if ! grep -q "NEXUS_ADMIN_USERNAME" "$ENV_FILE"; then
                sed -i "/NEXUS_ADMIN_PASSWORD/i NEXUS_ADMIN_USERNAME=${NEXUS_ADMIN_USERNAME}" "$ENV_FILE"
            fi

            # Add generation timestamp
            sed -i "1i# Generated on: $(date)" "$ENV_FILE"
            sed -i "1i# Based on .env.example template with secure credentials" "$ENV_FILE"

            chmod 600 "$ENV_FILE"
            print_status ".env file created from template with secure credentials" 0
            return 0
        fi
    fi

    # Generate .env file with essential configuration
    local env_content="# Nexus Docker Environment Configuration
# Generated on: $(date)

# Security Configuration (SECURE CREDENTIALS GENERATED)
NEXUS_SECURITY_RANDOMPASSWORD=false
NEXUS_ADMIN_USERNAME=${NEXUS_ADMIN_USERNAME}
NEXUS_ADMIN_PASSWORD=${NEXUS_ADMIN_PASSWORD}

# Database Configuration
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Network Configuration
NEXUS_HTTP_PORT=8081
NEXUS_DOCKER_PORT=8082
NEXUS_DOCKER_PROXY_PORT=8083
POSTGRES_PORT=5432

# Resource Configuration
NEXUS_MEMORY=2g
POSTGRES_MEMORY=512m

# SSL/TLS Configuration (customize as needed)
DOMAIN_NAME=nexus.example.com
REGISTRY_DOMAIN=registry.example.com"

    create_secure_file "$ENV_FILE" "$env_content"
    print_status ".env file created with essential secure configuration" 0
}

# Main execution
main() {
    echo -e "\nThis script will generate secure credentials for your Nexus deployment."
    echo -e "The default admin password 'admin123' will ${RED}NOT${NC} be used."
    echo ""

    # Check if credentials already exist
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        echo -e "${YELLOW}⚠ Credentials file already exists.${NC}"
        read -p "Do you want to regenerate credentials? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Using existing credentials."
            source "$CREDENTIALS_FILE"
            echo -e "${BLUE}Current admin password: ${NEXUS_ADMIN_PASSWORD}${NC}"
            return 0
        fi
    fi

    # Generate new secure password
    echo -e "${YELLOW}🔑 Generating secure admin password...${NC}"
    admin_password=$(generate_password)

    # Create credentials file
    create_credentials "$admin_password"

    # Create .env file
    create_env_file

    echo -e "\n${GREEN}✅ Security setup complete!${NC}"
    echo -e "\n${BLUE}Important Information:${NC}"
    echo -e "• Admin Username: ${YELLOW}admin${NC}"
    echo -e "• Admin Password: ${YELLOW}$admin_password${NC}"
    echo -e "• Credentials stored in: ${YELLOW}$CREDENTIALS_FILE${NC}"
    echo -e "• Environment config: ${YELLOW}$ENV_FILE${NC}"

    echo -e "\n${RED}⚠ SECURITY REMINDERS:${NC}"
    echo -e "• These files contain sensitive information"
    echo -e "• They are excluded from git via .gitignore"
    echo -e "• Do not share these credentials publicly"
    echo -e "• Consider using a password manager"

    echo -e "\n${BLUE}Next Steps:${NC}"
    echo -e "1. Start services: ${YELLOW}make start${NC}"
    echo -e "2. Run setup: ${YELLOW}make setup${NC}"
    echo -e "3. Access Nexus: ${YELLOW}http://localhost:8081${NC}"
    echo -e "\n${BLUE}Customization:${NC}"
    echo -e "• Edit ${YELLOW}$ENV_FILE${NC} to customize ports, domains, and features"
    echo -e "• See ${YELLOW}nexus-docker/.env.example${NC} for all available options"
}

# Check dependencies
if ! check_dependency "openssl"; then
    exit 1
fi

main "$@"

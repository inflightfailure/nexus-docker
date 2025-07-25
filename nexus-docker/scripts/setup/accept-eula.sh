#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043

# Nexus EULA Acceptance Script
# This script automatically accepts the Nexus Repository Community Edition EULA

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

set_strict_mode
setup_error_handling

print_section "Nexus EULA Acceptance Script"

# Load secure credentials
print_info "Loading secure credentials..."
load_credentials
if [[ $? -ne 0 ]]; then
    print_status "Failed to load secure credentials" 1
    print_info "Please run: ../../scripts/generate-credentials.sh"
    exit 1
fi

ADMIN_PASSWORD="$NEXUS_ADMIN_PASSWORD"

# Test API connectivity first
echo "Testing Nexus API connectivity..."
if ! curl -s -f -u "$NEXUS_USER":"$ADMIN_PASSWORD" "$NEXUS_URL"/service/rest/v1/status > /dev/null 2>&1; then
  echo -e "${RED}✗ Cannot connect to Nexus API at $NEXUS_URL${NC}"
  echo "Please ensure:"
  echo "1. Nexus is running (docker compose ps)"
  echo "2. The correct credentials are being used"
  echo "3. Wait a few minutes for Nexus to fully initialize"
  exit 1
fi

echo -e "${GREEN}✓ Nexus API is accessible${NC}"

# Get current EULA status
echo "Checking current EULA status..."
eula_status=$(curl -s -u "$NEXUS_USER":"$ADMIN_PASSWORD" "$NEXUS_URL"/service/rest/v1/system/eula 2>/dev/null)

if [ "$?" -ne 0 ] || [ -z "$eula_status" ]; then
  echo -e "${RED}✗ Failed to get EULA status${NC}"
  echo "This might indicate:"
  echo "1. EULA endpoint not available in this Nexus version"
  echo "2. Authentication issues"
  echo "3. Nexus not fully initialized yet"
  exit 1
fi

echo "Current EULA status: $eula_status"

# Check if EULA is already accepted
if echo "$eula_status" | grep -q '"accepted":true'; then
  echo -e "${GREEN}✓ EULA is already accepted${NC}"
  echo "You can now use the Nexus repositories!"
  exit 0
fi

# Accept EULA
echo "EULA not yet accepted. Accepting automatically..."
eula_response=$(curl -s -u "$NEXUS_USER":"$ADMIN_PASSWORD" -X POST \
  -H "Content-Type: application/json" \
  "$NEXUS_URL"/service/rest/v1/system/eula \
  -d '{
    "disclaimer": "Use of Sonatype Nexus Repository - Community Edition is governed by the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula. By returning the value from '\''accepted:false'\'' to '\''accepted:true'\'', you acknowledge that you have read and agree to the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula.",
    "accepted": true
  }' 2>&1)

eula_exit_code=$?

if [ $eula_exit_code -eq 0 ]; then
  echo -e "${GREEN}✓ EULA accepted successfully!${NC}"
  echo "Response: $eula_response"

  # Verify acceptance
  echo "Verifying EULA acceptance..."
  sleep 2
  verification=$(curl -s -u "$NEXUS_USER":"$ADMIN_PASSWORD" "$NEXUS_URL"/service/rest/v1/system/eula 2>/dev/null)

  if echo "$verification" | grep -q '"accepted":true'; then
    echo -e "${GREEN}✓ EULA acceptance verified${NC}"
    echo ""
    echo -e "${GREEN}🎉 Setup complete! You can now use all Nexus repositories.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the repository tests: ./test-repos.sh"
    echo "2. Access Nexus UI: $NEXUS_URL"
    echo "3. Use repositories for your package management"
  else
    echo -e "${YELLOW}⚠ EULA acceptance could not be verified${NC}"
    echo "Please check the Nexus UI manually: $NEXUS_URL"
  fi
else
  echo -e "${RED}✗ Failed to accept EULA${NC}"
  echo "Error response: $eula_response"
  echo ""
  echo "Manual steps:"
  echo "1. Open $NEXUS_URL in your browser"
  echo "2. Login with admin:$ADMIN_PASSWORD"
  echo "3. Complete the setup wizard and accept the EULA"
  exit 1
fi

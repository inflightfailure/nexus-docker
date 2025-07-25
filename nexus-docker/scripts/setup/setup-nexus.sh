#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043

# Comprehensive Nexus Setup Script
# Handles credential loading and EULA acceptance

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

set_strict_mode
setup_error_handling

print_section "Comprehensive Nexus Setup Script"

# Load secure credentials
print_info "Loading secure credentials..."
load_credentials
if [[ $? -ne 0 ]]; then
    print_status "Failed to load secure credentials" 1
    print_info "Please run: ../../scripts/generate-credentials.sh"
    exit 1
fi

ADMIN_PASSWORD="$NEXUS_ADMIN_PASSWORD"

# Test basic connectivity
echo "Testing Nexus connectivity..."
if ! curl -s -f "$NEXUS_URL" > /dev/null 2>&1; then
  echo -e "${RED}✗ Cannot connect to Nexus at $NEXUS_URL${NC}"
  echo "Please ensure Nexus is running: docker compose ps"
  exit 1
fi

echo -e "${GREEN}✓ Nexus is accessible${NC}"

# Test API authentication
echo "Testing API authentication..."
api_test=$(curl -s -w "%{http_code}" -u "$NEXUS_USER":"$ADMIN_PASSWORD" "$NEXUS_URL"/service/rest/v1/status 2>/dev/null)
http_code=$(echo "$api_test" | tail -c 4)

if [ "$http_code" = "200" ]; then
  echo -e "${GREEN}✓ API authentication successful${NC}"
elif [ "$http_code" = "401" ]; then
  echo -e "${YELLOW}⚠ Authentication failed - EULA may need to be accepted${NC}"
elif [ "$http_code" = "403" ]; then
  echo -e "${YELLOW}⚠ Access forbidden - EULA acceptance required${NC}"
else
  echo -e "${RED}✗ API test failed with HTTP $http_code${NC}"
  echo "Manual setup may be required via web UI"
fi

# Try to get and accept EULA
echo "Checking EULA status..."
eula_status=$(curl -s -u "$NEXUS_USER":"$ADMIN_PASSWORD" "$NEXUS_URL"/service/rest/v1/system/eula 2>/dev/null)
eula_exit_code=$?

if [ $eula_exit_code -eq 0 ] && [ -n "$eula_status" ]; then
  echo "EULA endpoint accessible"

  if echo "$eula_status" | grep -q '"accepted":true'; then
    echo -e "${GREEN}✓ EULA is already accepted${NC}"
  elif echo "$eula_status" | grep -q '"accepted":false'; then
    echo "EULA not yet accepted. Accepting now..."

    eula_response=$(curl -s -u "$NEXUS_USER":"$ADMIN_PASSWORD" -X POST \
      -H "Content-Type: application/json" \
      "$NEXUS_URL"/service/rest/v1/system/eula \
      -d '{
        "disclaimer": "Use of Sonatype Nexus Repository - Community Edition is governed by the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula. By returning the value from '\''accepted:false'\'' to '\''accepted:true'\'', you acknowledge that you have read and agree to the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula.",
        "accepted": true
      }' 2>&1)

    if [ "$?" -eq 0 ]; then
      echo -e "${GREEN}✓ EULA accepted successfully${NC}"
    else
      echo -e "${RED}✗ Failed to accept EULA: $eula_response${NC}"
    fi
  fi
else
  echo -e "${YELLOW}⚠ EULA endpoint not accessible${NC}"
  echo "This may indicate:"
  echo "1. Nexus version doesn't support this API"
  echo "2. Authentication issues"
  echo "3. Initial setup required via web UI"
fi

# Final API test
echo "Performing final API connectivity test..."
sleep 2
final_test=$(curl -s -w "%{http_code}" -u "$NEXUS_USER":"$ADMIN_PASSWORD" "$NEXUS_URL"/service/rest/v1/status 2>/dev/null)
final_http_code=$(echo "$final_test" | tail -c 4)

if [ "$final_http_code" = "200" ]; then
  echo -e "${GREEN}✓ Setup completed successfully!${NC}"
  echo ""
  echo -e "${GREEN}🎉 Nexus is ready to use!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Run repository tests: ./test-repos.sh"
  echo "2. Access Nexus UI: $NEXUS_URL"
  echo "3. Default credentials: admin:$ADMIN_PASSWORD"
else
  echo -e "${YELLOW}⚠ API still not fully accessible (HTTP $final_http_code)${NC}"
  echo ""
  echo "Manual setup required:"
  echo "1. Open $NEXUS_URL in your browser"
  echo "2. Login with admin:$ADMIN_PASSWORD"
  echo "3. Complete the setup wizard"
  echo "4. Accept the EULA when prompted"
fi

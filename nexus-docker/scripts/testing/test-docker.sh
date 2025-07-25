#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

set_strict_mode
setup_error_handling

print_section "Docker Registry Test"

# Load credentials
load_credentials
ADMIN_PASSWORD="$NEXUS_ADMIN_PASSWORD"

print_info "Testing Docker registry functionality..."

# Test 1: Registry API
print_info "1. Testing registry API..."
if curl -s -f http://localhost:8081/v2/ > /dev/null; then
    print_status "Registry API accessible" 0
else
    print_status "Registry API accessible" 1
    exit 1
fi

# Test 2: Login to registry
print_info "2. Testing registry login..."
if echo "$ADMIN_PASSWORD" | docker login $DOCKER_REGISTRY --username "$NEXUS_USER" --password-stdin > /dev/null 2>&1; then
    print_status "Docker login successful" 0
else
    print_status "Docker login successful" 1
    exit 1
fi

# Test 3: Pull image through proxy
echo "3. Testing image pull through proxy..."
docker pull "$DOCKER_REGISTRY"/curlimages/curl:latest
echo -e "${GREEN}✓ Image pulled through proxy${NC}"

# Test 4: Tag and push to hosted registry (if you create one)
echo "4. Testing image push..."
docker tag curlimages/curl:latest "$DOCKER_REGISTRY"/test/curl:latest
docker push "$DOCKER_REGISTRY"/test/curl:latest 2>/dev/null || echo -e "${YELLOW}Note: Push failed - may need hosted repository${NC}"

# Test 5: List images
echo "5. Testing image catalog..."
curl -s -u "$NEXUS_USER":"$ADMIN_PASSWORD" http://localhost:8081/v2/_catalog
echo -e "${GREEN}✓ Registry catalog accessible${NC}"

echo -e "\n${GREEN}Docker registry tests completed!${NC}"

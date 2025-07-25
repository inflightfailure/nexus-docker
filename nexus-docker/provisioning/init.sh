#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043
set -e

echo "Waiting for Nexus to fully initialize with PostgreSQL..."
sleep 30  # PostgreSQL setup takes longer

# Get admin password
get_admin_password() {
  if [ -f /nexus-data/admin.password ]; then
    cat /nexus-data/admin.password
  else
    echo "admin123"  # Default password when NEXUS_SECURITY_RANDOMPASSWORD=false
  fi
}

# Wait for admin password file with timeout (but don't require it if using default password)
echo "Waiting for admin password file or timeout for default setup..."
timeout=120  # 2 minutes - shorter timeout when using default password
while [ ! -f /nexus-data/admin.password ] && [ $timeout -gt 0 ]; do
  sleep 5
  timeout=$((timeout - 5))
done

if [ ! -f /nexus-data/admin.password ]; then
  echo "No admin.password file found - using default password setup"
else
  echo "Found admin.password file"
fi

ADMIN_PASSWORD=$(get_admin_password)
echo "Retrieved admin password (length: ${#ADMIN_PASSWORD})"

# Wait for API and test authentication with better error handling
echo "Testing Nexus API authentication..."
max_retries=20
retry_count=0

while [ $retry_count -lt $max_retries ]; do
  if curl -s -u admin:"$ADMIN_PASSWORD" -f http://nexus:8081/service/rest/v1/status > /dev/null 2>&1; then
    echo "✓ API authentication successful"
    break
  else
    retry_count=$((retry_count + 1))
    echo "API not ready or authentication failed, retry $retry_count/$max_retries..."
    sleep 15
  fi
done

if [ $retry_count -eq $max_retries ]; then
  echo "⚠ API authentication failed after $max_retries attempts"
  echo "This may indicate EULA acceptance is required"
  echo "Please run ./setup-nexus.sh from the host or complete setup via web UI"
  echo "Continuing with repository creation anyway..."
fi

# Handle EULA acceptance via REST API
echo "Checking and accepting EULA..."

# First, get the current EULA status
eula_status=$(curl -s -u admin:"$ADMIN_PASSWORD" http://nexus:8081/service/rest/v1/system/eula 2>/dev/null || echo '{"accepted": false}')
echo "Current EULA status: $eula_status"

if echo "$eula_status" | grep -q '"accepted":false'; then
  echo "EULA not yet accepted, accepting automatically..."

  # Accept EULA using the official REST API
  eula_response=$(curl -s -u admin:"$ADMIN_PASSWORD" -X POST \
    -H "Content-Type: application/json" \
    http://nexus:8081/service/rest/v1/system/eula \
    -d '{
      "disclaimer": "Use of Sonatype Nexus Repository - Community Edition is governed by the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula. By returning the value from '\''accepted:false'\'' to '\''accepted:true'\'', you acknowledge that you have read and agree to the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula.",
      "accepted": true
    }' 2>&1)

  if [ "$?" -eq 0 ]; then
    echo "EULA accepted successfully: $eula_response"
    # Wait a moment for changes to take effect
    sleep 5
  else
    echo "Failed to accept EULA: $eula_response"
    echo "You may need to complete EULA acceptance manually via the web UI"
  fi
else
  echo "EULA already accepted"
fi

echo "Creating repositories using REST API..."

# Function to list repositories (with better parsing)
list_repositories() {
  local response=$(curl -s -u admin:$ADMIN_PASSWORD http://nexus:8081/service/rest/v1/repositories)

  # Debug: show first 200 characters of response
  echo "Debug - API response preview: $(echo "$response" | head -c 200)..."

  # Try multiple parsing methods
  echo "Repositories found:"

  # Method 1: Extract names with grep and sed
  echo "$response" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//' | sort

  # If that fails, try alternative parsing
  if [ "$?" -ne 0 ]; then
    echo "Alternative parsing:"
    echo "$response" | sed 's/.*"name":"\([^"]*\)".*/\1/g' | sort
  fi

  # Method 2: If available, use jq for proper JSON parsing
  if command -v jq >/dev/null 2>&1; then
    echo "Using jq for JSON parsing:"
    echo "$response" | jq -r '.[].name' | sort
  fi
}

# Fixed function to check if repository exists
repo_exists() {
  local repo_name=$1

  # Method 1: Check if repository exists in the list
  local response=$(curl -s -u admin:$ADMIN_PASSWORD http://nexus:8081/service/rest/v1/repositories)
  if echo "$response" | grep -q "\"name\":\"$repo_name\""; then
    echo "Found $repo_name in repository list"
    return 0
  fi

  # Method 2: Direct check - only return true if we get a 200 response
  local http_code=$(curl -s -o /dev/null -w "%{http_code}" -u admin:$ADMIN_PASSWORD "http://nexus:8081/service/rest/v1/repositories/$repo_name")
  if [ "$http_code" = "200" ]; then
    echo "Found $repo_name via direct API call"
    return 0
  fi

  echo "$repo_name does not exist (HTTP $http_code)"
  return 1
}

# Function to create repository with better error handling
create_repository() {
  local repo_name=$1
  local repo_type=$2
  local json_data=$3

  echo "Checking if $repo_name repository exists..."
  if repo_exists "$repo_name"; then
    echo "$repo_name repository already exists, skipping creation"
    return 0
  fi

  echo "Creating $repo_name repository..."
  local response=$(curl -s -u admin:$ADMIN_PASSWORD -X POST \
    -H "Content-Type: application/json" \
    -w "\n%{http_code}" \
    "http://nexus:8081/service/rest/v1/repositories/$repo_type" \
    -d "$json_data")

  local http_code=$(echo "$response" | tail -n1)
  local body=$(echo "$response" | head -n -1)

  if [ "$http_code" = "201" ] || [ "$http_code" = "204" ]; then
    echo "$repo_name repository created successfully"
    return 0
  elif [ "$http_code" = "400" ] && echo "$body" | grep -qi "duplicate\|already.*exist"; then
    echo "$repo_name repository already exists (detected from error message)"
    return 0
  else
    echo "Failed to create $repo_name repository (HTTP $http_code): $body"
    return 1
  fi
}

# Check what blob stores exist
echo "Checking existing blob stores..."
curl -s -u admin:$ADMIN_PASSWORD http://nexus:8081/service/rest/v1/blobstores | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//' || echo "No blob stores found or parsing failed"

# Create blob store if it doesn't exist
echo "Creating default blob store..."
blob_response=$(curl -s -u admin:$ADMIN_PASSWORD http://nexus:8081/service/rest/v1/blobstores)
if echo "$blob_response" | grep -q '"name":"default"'; then
  echo "Default blob store already exists"
else
  echo "Creating default blob store..."
  curl -s -u admin:$ADMIN_PASSWORD -X POST http://nexus:8081/service/rest/v1/blobstores/file \
    -H "Content-Type: application/json" \
    -d '{
      "name": "default",
      "path": "default",
      "softQuota": {
        "type": "spaceRemainingQuota",
        "limit": 1000000000
      }
    }' && echo "Default blob store created" || echo "Failed to create default blob store"
fi

# List existing repositories before creation
echo "Existing repositories before creation:"
list_repositories

# Create Maven Central proxy repository
create_repository "maven-central" "maven/proxy" '{
  "name": "maven-central",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "proxy": {
    "remoteUrl": "https://repo1.maven.org/maven2/",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  },
  "maven": {
    "versionPolicy": "RELEASE",
    "layoutPolicy": "STRICT"
  }
}'

# Create NPM proxy repository
create_repository "npm-proxy" "npm/proxy" '{
  "name": "npm-proxy",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "proxy": {
    "remoteUrl": "https://registry.npmjs.org",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  }
}'

# Create PyPI proxy repository
create_repository "pypi-proxy" "pypi/proxy" '{
  "name": "pypi-proxy",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "proxy": {
    "remoteUrl": "https://pypi.org",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  }
}'

# Create Docker Hub proxy repository
create_repository "docker-hub" "docker/proxy" '{
  "name": "docker-hub",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "proxy": {
    "remoteUrl": "https://registry-1.docker.io",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "httpPort": 8082
  },
  "dockerProxy": {
    "indexType": "HUB"
  }
}'

echo "Repository provisioning completed"

# List all repositories for verification
echo "Final repository list:"
list_repositories

# Nexus Repository Setup Guide

## Automated Solution

I've created automated EULA acceptance solutions using the official Nexus REST API. Here are your options:

### Option 1: Comprehensive Setup Script (Recommended)

Run the comprehensive setup script that handles all scenarios:

```bash
./setup-nexus.sh
```

This script will:

- Detect the correct admin password (from file or default)
- Test connectivity and authentication
- Automatically accept the EULA using the REST API
- Provide clear next steps based on the current state

### Option 2: EULA-only Script

If you know the API is accessible, run the EULA-specific script:

```bash
./accept-eula.sh
```

### Option 3: Manual Web UI Setup

If the automated scripts indicate manual setup is required:

1. **Access Nexus UI**: Open <http://localhost:8081> in your browser

2. **Complete Initial Setup**:
   - Username: `admin`
   - Password: `admin123` (default password) # pragma: allowlist secret
   - Accept the EULA when prompted
   - Complete the setup wizard

### Option 3: Direct API Call

You can also accept the EULA directly using curl:

```bash
curl -u admin:admin123 -X POST 'http://localhost:8081/service/rest/v1/system/eula' \
  -H 'Content-Type: application/json' \
  -d '{
    "disclaimer": "Use of Sonatype Nexus Repository - Community Edition is governed by the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula. By returning the value from '\''accepted:false'\'' to '\''accepted:true'\'', you acknowledge that you have read and agree to the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula.",
    "accepted": true
  }'
```

## Testing Repositories

After EULA acceptance, run the comprehensive test suite:

```bash
./test-repos.sh
```

## Troubleshooting

### If you get 401 Unauthorized errors

- The EULA hasn't been accepted yet
- Complete the web UI setup first

### If the init script is stuck

```bash
# Stop the init container
docker compose stop nexus-init

# Complete the web UI setup manually
# Then run the test script directly
./test-repos.sh
```

### Repository Endpoints

- **Nexus UI**: <http://localhost:8081>
- **Docker Registry**: localhost:8082
- **Maven Central Proxy**: <http://localhost:8081/repository/maven-central/>
- **NPM Proxy**: <http://localhost:8081/repository/npm-proxy/>
- **PyPI Proxy**: <http://localhost:8081/repository/pypi-proxy/>

## Expected Test Results After Setup

Once EULA is accepted, all repository tests should pass:

- ✓ Nexus API connectivity
- ✓ Maven Central proxy
- ✓ NPM proxy  
- ✓ PyPI proxy
- ✓ Docker Hub proxy
- ✓ Package installations through proxies

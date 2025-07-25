# Setup Scripts

This directory contains scripts for initial Nexus Repository Manager setup and configuration.

## Scripts Overview

### `setup-nexus.sh`

**Purpose**: Comprehensive setup script that handles all aspects of initial Nexus configuration.

**Features**:

- Detects the correct admin password (from container or uses default)
- Tests API connectivity and authentication
- Automatically accepts the EULA using the official REST API
- Provides clear status feedback and next steps
- Handles various error scenarios gracefully

**Usage**:

```bash
./setup-nexus.sh
```

**What it does**:

1. Checks if Nexus container is running
2. Retrieves or uses default admin password
3. Waits for Nexus API to become available
4. Checks current EULA acceptance status
5. Accepts EULA if not already accepted
6. Verifies setup completion

### `accept-eula.sh`

**Purpose**: Standalone script focused specifically on EULA acceptance.

**Features**:

- Uses official Nexus REST API endpoint
- Handles authentication automatically
- Provides clear success/failure feedback
- Can be run independently when API is already accessible

**Usage**:

```bash
./accept-eula.sh
```

**When to use**:

- When you know the Nexus API is accessible
- For automated deployments where you only need EULA acceptance
- As a troubleshooting step when setup-nexus.sh indicates EULA issues

## Common Usage Patterns

### First-time Setup

```bash
# Start services
make start

# Run comprehensive setup
./setup-nexus.sh

# Verify with tests
make test
```

### Troubleshooting EULA Issues

```bash
# If you encounter EULA errors in tests
./accept-eula.sh

# Or run full setup again
./setup-nexus.sh
```

### Automated Deployment

```bash
# In CI/CD pipelines or automation scripts
docker-compose up -d
sleep 30  # Wait for services to start
./scripts/setup/setup-nexus.sh
./scripts/testing/test-repos.sh
```

## Technical Details

### EULA Acceptance Process

The EULA acceptance uses the official Sonatype REST API:

- **Endpoint**: `POST /service/rest/v1/system/eula`
- **Authentication**: Basic auth with admin credentials
- **Payload**: JSON with disclaimer text and acceptance flag

### Error Handling

Both scripts include comprehensive error handling for:

- Container not running
- API not accessible
- Authentication failures
- Network timeouts
- Invalid responses

### Dependencies

These scripts depend on:

- `../common.sh` - Shared utilities and functions
- Docker and docker-compose
- curl for API calls
- Standard Unix utilities (grep, cat, etc.)

## Troubleshooting

### Script Fails with "Container Not Running"

```bash
# Check container status
docker-compose ps

# Start if needed
make start

# Wait a moment and retry
./setup-nexus.sh
```

### Script Fails with "API Not Accessible"

```bash
# Check if Nexus is still starting up
docker logs nexus

# Wait longer and retry
sleep 60
./setup-nexus.sh
```

### Authentication Errors

```bash
# Get the actual admin password
docker exec nexus cat /nexus-data/admin.password

# If file doesn't exist, use default: admin123
```

### Network Issues

```bash
# Test basic connectivity
curl -f http://localhost:8081/service/rest/v1/status

# Check if services are bound to correct ports
netstat -tlnp | grep -E ':(8081|8082|8083)'
```

## Advanced Usage

### Custom Configuration

You can modify variables at the top of scripts:

```bash
# In setup-nexus.sh or accept-eula.sh
NEXUS_URL="http://localhost:8081"  # Change if using different port
NEXUS_USER="admin"                 # Change if using different admin user
```

### Integration with Other Scripts

Both scripts are designed to be sourced or called from other scripts:

```bash
#!/bin/bash
source scripts/common.sh

# Run setup
./scripts/setup/setup-nexus.sh

# Continue with your logic
if [ $? -eq 0 ]; then
    echo "Setup successful, proceeding..."
    # Your code here
fi
```

## Output Examples

### Successful Setup

```
Getting Nexus admin password...
✓ Admin password retrieved from container
Testing Nexus API connectivity...
✓ Nexus API connectivity
Checking EULA acceptance status...
✓ EULA is already accepted
✓ Nexus setup completed successfully
```

### EULA Acceptance Required

```
Getting Nexus admin password...
✓ Using default admin password (admin123)
Testing Nexus API connectivity...
✓ Nexus API connectivity
Checking EULA acceptance status...
⚠ EULA not yet accepted
Accepting EULA...
✓ EULA accepted successfully
✓ Nexus setup completed successfully
```

Repository creation logic in `provisioning/init.sh`

## Docker Registry Usage

```bash
# Configure Docker daemon
echo '{"insecure-registries": ["localhost:8082"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# Login and push
docker login localhost:8082
docker tag myimage:latest localhost:8082/myimage:latest
docker push localhost:8082/myimage:latest
```

## Data Persistence

- **nexus-data/**: Nexus application data and blob storage
- **postgres-data/**: PostgreSQL database files

## Environment Variables

Key environment variables in docker-compose.yml:

- `NEXUS_DATASTORE_ENABLED=true`: Enable PostgreSQL backend
- `NEXUS_DATASTORE_NEXUS_JDBCURL`: PostgreSQL connection string
- Database credentials: nexus/nexus-password

## Additional Troubleshooting

Check service logs:

```bash
docker-compose logs nexus
docker-compose logs postgres
docker-compose logs nexus-init
```

Check repository creation:

```bash
docker-compose logs nexus-init
```

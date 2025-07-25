# Testing Scripts

This directory contains comprehensive test suites for validating Nexus Repository Manager functionality.

## Scripts Overview

### `test-repos.sh`

**Purpose**: Comprehensive test suite covering all repository types and functionality.

**Features**:

- Tests all configured repository proxies (Maven, NPM, PyPI, Docker)
- Validates package installation through proxies
- Includes authentication and connectivity tests
- Provides detailed error diagnostics
- Comprehensive test reporting

**Usage**:

```bash
./test-repos.sh
```

**Test Coverage**:

1. API connectivity and authentication
2. Maven Central proxy access
3. NPM proxy functionality  
4. PyPI proxy operations
5. Docker Hub proxy and registry
6. Package installation tests (pip, npm)
7. Repository statistics and health

### `test-pypi.sh`

**Purpose**: Specialized PyPI proxy testing with virtual environment isolation.

**Features**:

- Creates isolated Python virtual environment
- Tests pip configuration with Nexus proxy
- Package installation validation
- Handles Python version compatibility
- Automatic cleanup

**Usage**:

```bash
./test-pypi.sh
```

**What it tests**:

- PyPI proxy accessibility
- pip configuration with authentication
- Package installation (requests library)
- Virtual environment handling

### `test-docker.sh`

**Purpose**: Docker registry functionality testing.

**Features**:

- Docker daemon configuration validation
- Registry API connectivity
- Image pull/push operations
- Authentication testing
- Insecure registry handling

**Usage**:

```bash
./test-docker.sh
```

**What it tests**:

- Docker registry endpoint availability
- Authentication with registry
- Image pull operations
- Docker daemon configuration

### `test-runner.sh`

**Purpose**: Orchestrates all test suites and provides unified reporting.

**Features**:

- Runs all available test scripts
- Aggregates results across test suites
- Provides comprehensive summary
- Handles test dependencies

**Usage**:

```bash
./test-runner.sh
```

## Test Execution Patterns

### Quick Validation

```bash
# Run main test suite
make test
# or
./test-repos.sh
```

### Comprehensive Testing

```bash
# Run all test suites
make test-all
# or  
./test-runner.sh
```

### Individual Component Tests

```bash
# Test specific functionality
./test-pypi.sh      # PyPI-specific tests
./test-docker.sh    # Docker registry tests
```

### Automated Testing

```bash
# In CI/CD pipelines
docker-compose up -d
./scripts/setup/setup-nexus.sh
./scripts/testing/test-runner.sh
```

## Test Configuration

### Environment Variables

Tests use configuration from `../common.sh`:

- `NEXUS_URL`: Nexus server URL (default: <http://localhost:8081>)
- `DOCKER_REGISTRY`: Docker registry endpoint (default: localhost:8082)  
- `NEXUS_USER`: Admin username (default: admin)

### Credentials

Tests automatically retrieve admin password:

1. From container: `docker exec nexus cat /nexus-data/admin.password`
2. Fallback to default: `admin123`

## Test Output and Reporting

### Status Indicators

- ✓ Green checkmark: Test passed
- ✗ Red X: Test failed  
- ⚠ Yellow warning: Test skipped

### Test Summary

Each script provides a summary:

```
=== Test Summary ===
Tests passed: 9
Tests failed: 0  
Tests skipped: 0
All tests completed successfully!
```

### Debug Information

Failed tests include diagnostic information:

- HTTP response codes
- Error messages
- Configuration suggestions
- Troubleshooting steps

## Common Test Scenarios

### After Initial Setup

```bash
# Verify everything is working
make start
make setup
make test
```

### Troubleshooting Issues

```bash
# Run tests to identify problems
./test-repos.sh

# Focus on specific component
./test-pypi.sh      # If pip issues
./test-docker.sh    # If Docker issues
```

### Validating Changes

```bash
# After configuration changes
make restart
./test-runner.sh
```

## Test Requirements

### System Dependencies

- Docker and docker-compose
- curl for HTTP requests
- Python 3 and pip (for PyPI tests)
- npm (for NPM tests)
- Standard Unix utilities

### Network Requirements

- Internet access for proxy repositories
- Ports 8081, 8082, 8083 accessible
- Docker daemon configured for insecure registries

### Container Dependencies

- Nexus container running and healthy
- PostgreSQL container accessible
- EULA accepted (run setup scripts first)

## Troubleshooting Test Failures

### Authentication Errors

```bash
# Verify EULA acceptance
./scripts/setup/accept-eula.sh

# Check credentials
docker exec nexus cat /nexus-data/admin.password
```

### Network Issues

```bash
# Test basic connectivity
curl -f http://localhost:8081/service/rest/v1/status

# Check port bindings
docker-compose ps
netstat -tlnp | grep -E ':(8081|8082)'
```

### Package Installation Failures

```bash
# For PyPI issues
./test-pypi.sh      # Run detailed PyPI tests

# For NPM issues  
npm config list    # Check NPM configuration
```

### Docker Registry Issues

```bash
# Check Docker daemon configuration
cat /etc/docker/daemon.json

# Should contain: "insecure-registries": ["localhost:8082"]
```

## Extending Tests

### Adding New Repository Tests

1. Add test logic to `test-repos.sh`
2. Use functions from `../common.sh`
3. Follow existing pattern for status reporting
4. Include error diagnostics

### Creating New Test Scripts

```bash
#!/bin/bash
source ../common.sh

print_section "New Component Tests"

# Your test logic here
if test_condition; then
    print_status "New test description" 0
else  
    print_status "New test description" 1
fi

print_test_summary
```

## Performance Considerations

### Test Timeouts

- HTTP requests: 30-second timeout
- Package installations: 120-second timeout  
- Docker operations: 60-second timeout

### Resource Usage

- Tests create temporary directories/environments
- Automatic cleanup after completion
- Minimal persistent state changes

### Parallel Execution

- Tests are designed to run sequentially
- Avoid running multiple test scripts simultaneously
- Some tests may interfere with each other

## Integration Examples

### CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Test Nexus Setup
  run: |
    make start
    sleep 60
    make setup
    make test-all
```

### Health Check Script

```bash
#!/bin/bash
# Simple health check
if ./scripts/testing/test-repos.sh > /dev/null 2>&1; then
    echo "Nexus healthy"
    exit 0
else
    echo "Nexus unhealthy"  
    exit 1
fi
```

### Monitoring Integration

```bash
# Export test results for monitoring
./test-repos.sh | grep "Tests passed:" | awk '{print $3}'
```

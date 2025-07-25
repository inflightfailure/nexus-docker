# Nexus Repository Manager Docker

A comprehensive Docker Compose setup for Nexus Repository Manager with PostgreSQL backend, Traefik reverse proxy, and automated repository provisioning.

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Scripts Reference](#scripts-reference)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## Quick Start

1. **Clone and navigate to the repository**:

   ```bash
   git clone <repository-url>
   cd nexus-docker/nexus-docker
   ```

2. **Start all services**:

   ```bash
   make start
   ```

3. **Run initial setup** (accepts EULA and configures Nexus):

   ```bash
   make setup
   ```

4. **Test repository functionality**:

   ```bash
   make test
   ```

5. **Access Nexus**:
   - Web UI: <http://localhost:8081>
   - Docker registry: <http://localhost:8082>
   - Default credentials: admin/admin123

## Architecture

### Services

- **Nexus Repository Manager**: Main repository service (ports 8081, 8082, 8083)
- **PostgreSQL 17**: Database backend with optimized configuration
- **Traefik**: Reverse proxy with SSL termination and automatic certificate management
- **nexus-init**: Automated repository provisioning container

### Repository Types

The setup automatically creates and configures:

- **Maven Central Proxy**: `maven-central`
- **NPM Registry Proxy**: `npm-proxy`
- **PyPI Proxy**: `pypi-proxy`
- **Docker Hub Proxy**: `docker-hub`

## Configuration

### Directory Structure

```
nexus-docker/
├── config/
│   ├── postgres/          # PostgreSQL configuration
│   └── traefik/          # Traefik and SSL certificates
├── docs/                 # Documentation
├── scripts/
│   ├── setup/           # Setup and initialization scripts
│   ├── testing/         # Testing and validation scripts
│   └── common.sh        # Shared utilities
├── provisioning/        # Container initialization scripts
├── docker-compose.yml   # Main service definition
└── makefile            # Common operations
```

### Environment Variables

Key configuration options in `docker-compose.yml`:

- `NEXUS_SECURITY_RANDOMPASSWORD`: Set to `false` for predictable admin password
- `POSTGRES_*`: Database connection settings
- `TRAEFIK_*`: Reverse proxy configuration

### SSL/TLS Configuration

Generate certificates for HTTPS:

```bash
cd config/traefik/certs
./generate-certs.sh
```

## Scripts Reference

### Setup Scripts (`scripts/setup/`)

- **`setup-nexus.sh`**: Comprehensive setup script that handles EULA acceptance and initial configuration
- **`accept-eula.sh`**: Standalone EULA acceptance script
- **`README.md`**: Setup script documentation

### Testing Scripts (`scripts/testing/`)

- **`test-repos.sh`**: Comprehensive repository functionality tests
- **`test-pypi.sh`**: Dedicated PyPI proxy testing
- **`test-docker.sh`**: Docker registry testing
- **`test-runner.sh`**: Orchestrates all test suites

### Common Utilities

- **`scripts/common.sh`**: Shared functions and variables used by all scripts

## Testing

### Quick Test

```bash
make test
```

### Comprehensive Testing

```bash
make test-all
```

### Individual Tests

```bash
./scripts/testing/test-repos.sh    # All repository types
./scripts/testing/test-pypi.sh     # PyPI-specific tests
./scripts/testing/test-docker.sh   # Docker registry tests
```

### Test Coverage

The test suite validates:

- API connectivity and authentication
- Repository proxy functionality
- Package installation through proxies
- Docker registry operations
- EULA acceptance status

## Troubleshooting

### Common Issues

1. **EULA Not Accepted**: Run `make setup` or `./scripts/setup/setup-nexus.sh`
2. **Container Not Starting**: Check logs with `make logs`
3. **Port Conflicts**: Ensure ports 8081, 8082, 8083, 5432 are available
4. **Docker Registry Issues**: Verify `/etc/docker/daemon.json` includes insecure registries

### Debug Commands

```bash
# View all service logs
make logs

# Check container status
docker-compose ps

# Get admin password
docker exec nexus cat /nexus-data/admin.password

# Test API connectivity
curl -u admin:admin123 http://localhost:8081/service/rest/v1/status
```

### Performance Tuning

For production use, consider:

- Increasing heap size in `docker-compose.yml`
- Configuring blob store cleanup policies
- Setting up repository health checks
- Implementing backup strategies

## Development

### Code Quality and Security

This repository includes comprehensive pre-commit hooks for:

- **Security scanning**: Detects secrets, private keys, and credentials
- **Code linting**: Shell script analysis with ShellCheck
- **Format validation**: YAML, JSON, Markdown consistency
- **Docker best practices**: Dockerfile linting with Hadolint

```bash
# Install and setup pre-commit hooks
pip3 install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Run checks manually
make lint
```

See [PRECOMMIT.md](PRECOMMIT.md) for detailed documentation.

### Adding New Repository Types

1. Update `provisioning/init.sh` with new repository creation
2. Add tests to `scripts/testing/test-repos.sh`
3. Update documentation

### Contributing

1. Follow the existing script structure
2. Use functions from `scripts/common.sh`
3. Add appropriate tests
4. Update documentation

### Makefile Commands

```bash
make help      # Show all available commands
make start     # Start services
make stop      # Stop services
make restart   # Restart services
make setup     # Initial setup
make test      # Run tests
make clean     # Clean up volumes and containers
make logs      # View logs
```

## Security Considerations

- Change default passwords in production
- Configure proper SSL certificates
- Restrict network access as needed
- Regular security updates for base images
- Monitor access logs

## License

See LICENSE file for details.

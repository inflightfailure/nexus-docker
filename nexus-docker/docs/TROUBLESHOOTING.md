# Troubleshooting Guide

This guide covers common issues and their solutions when working with the Nexus Docker setup.

## Quick Diagnosis

Run the comprehensive test suite to identify issues:

```bash
make test
```

## Common Issues

### 1. EULA Not Accepted

**Symptoms:**

- HTTP 403 errors when accessing repositories
- "EULA acceptance required" messages in logs
- Repository tests failing with authentication errors

**Solutions:**

```bash
# Automated solution (recommended)
make setup

# Manual solution
./scripts/setup/accept-eula.sh

# Web UI solution
# Visit http://localhost:8081 and complete setup wizard
```

**Verification:**

```bash
curl -u admin:admin123 http://localhost:8081/service/rest/v1/system/eula
# Should return: "accepted": true
```

### 2. Container Not Starting

**Symptoms:**

- `docker-compose up` fails
- Services exit immediately
- Port binding errors

**Diagnosis:**

```bash
# Check service status
docker-compose ps

# View logs
make logs

# Check port conflicts
netstat -tlnp | grep -E ':(8081|8082|8083|5432)'
```

**Solutions:**

```bash
# Stop conflicting services
sudo systemctl stop postgresql  # If PostgreSQL is running locally

# Clean up and restart
make clean
make start

# Check disk space
df -h
```

### 3. Database Connection Issues

**Symptoms:**

- Nexus fails to start with database errors
- PostgreSQL connection failures in logs

**Diagnosis:**

```bash
# Check PostgreSQL container
docker exec postgres-nexus psql -U nexus -d nexus -c '\dt'

# View PostgreSQL logs
docker logs postgres-nexus
```

**Solutions:**

```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres-nexus
# Wait for postgres to be ready, then start nexus
docker-compose up -d nexus
```

### 4. Repository Access Issues

**Symptoms:**

- 401/403 errors when accessing repositories
- Package installation failures
- Docker registry login failures

**Diagnosis:**

```bash
# Test API connectivity
curl -u admin:admin123 http://localhost:8081/service/rest/v1/status

# Check repository configuration
curl -u admin:admin123 http://localhost:8081/service/rest/v1/repositories

# Test specific repository
curl -u admin:admin123 http://localhost:8081/repository/maven-central/
```

**Solutions:**

```bash
# Verify credentials
docker exec nexus cat /nexus-data/admin.password

# Re-run setup
make setup

# Check EULA status
./scripts/setup/accept-eula.sh
```

### 5. Docker Registry Issues

**Symptoms:**

- Docker pull/push failures
- Registry authentication errors
- Connection refused errors

**Configuration Check:**

```bash
# Verify insecure registry configuration
cat /etc/docker/daemon.json
# Should contain: "insecure-registries": ["localhost:8082"]
```

**Solutions:**

```bash
# Add insecure registry configuration
sudo tee /etc/docker/daemon.json << EOF
{
  "insecure-registries": ["localhost:8082"]
}
EOF

# Restart Docker daemon
sudo systemctl restart docker

# Restart docker-compose
make restart

# Test registry
docker pull localhost:8082/hello-world
```

### 6. Package Installation Issues

#### NPM Issues

**Symptoms:**

- npm install failures
- Authentication errors
- Package not found errors

**Solutions:**

```bash
# Configure npm for Nexus proxy
npm config set registry http://localhost:8081/repository/npm-proxy/
npm config set "//localhost:8081/repository/npm-proxy/:_auth" $(echo -n "admin:admin123" | base64)

# Test installation
npm install express --no-save

# Clean up
npm config delete registry
npm config delete "//localhost:8081/repository/npm-proxy/:_auth"
```

#### PyPI Issues

**Symptoms:**

- pip install failures
- SSL certificate errors
- Package compilation errors

**Solutions:**

```bash
# Create pip configuration
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
index-url = http://admin:admin123@localhost:8081/repository/pypi-proxy/simple  # pragma: allowlist secret
trusted-host = localhost
timeout = 60
retries = 3
EOF

# Test installation
pip install requests==2.31.0

# Clean up
rm ~/.pip/pip.conf
```

### 7. Performance Issues

**Symptoms:**

- Slow repository responses
- High memory usage
- Container restarts

**Diagnosis:**

```bash
# Check resource usage
docker stats

# Check disk usage
docker system df

# Check Nexus heap usage
docker exec nexus cat /opt/sonatype/nexus/bin/nexus.vmoptions
```

**Solutions:**

```bash
# Increase heap size in docker-compose.yml
# Add to nexus service environment:
NEXUS_OPTS: "-Xms2g -Xmx2g"

# Clean up unused data
make clean
docker system prune -a
```

### 8. SSL/Certificate Issues

**Symptoms:**

- Certificate validation errors
- HTTPS access failures
- Browser security warnings

**Solutions:**

```bash
# Regenerate certificates
cd config/traefik/certs
rm -rf certs/
./generate-certs.sh

# Restart services
make restart

# Add certificates to system trust store (varies by OS)
# For Ubuntu/Debian:
sudo cp config/traefik/certs/certs/nexus.example.com.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

## Advanced Debugging

### Enable Debug Logging

Add to `docker-compose.yml` nexus service:

```yaml
environment:
  - NEXUS_OPTS=-Dcom.sonatype.nexus.log.level=DEBUG
```

### Container Shell Access

```bash
# Access Nexus container
docker exec -it nexus bash

# Access PostgreSQL container
docker exec -it postgres-nexus bash

# Check Nexus configuration
docker exec nexus find /nexus-data -name "*.properties" -exec cat {} \;
```

### Network Debugging

```bash
# Check container networking
docker network ls
docker network inspect nexus_default

# Test inter-container connectivity
docker exec nexus ping postgres-nexus
docker exec nexus curl -I http://traefik:8080/ping
```

### Backup and Recovery

```bash
# Backup Nexus data
docker run --rm -v nexus_nexus-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/nexus-backup.tar.gz -C /data .

# Restore Nexus data
docker run --rm -v nexus_nexus-data:/data -v $(pwd):/backup alpine \
  tar xzf /backup/nexus-backup.tar.gz -C /data
```

## Getting Help

### Log Collection

Before seeking help, collect relevant logs:

```bash
# Save all logs
make logs > nexus-logs.txt

# Get system information
docker version > system-info.txt
docker-compose version >> system-info.txt
uname -a >> system-info.txt
```

### Common Log Locations

- Nexus logs: `docker logs nexus`
- PostgreSQL logs: `docker logs postgres-nexus`
- Traefik logs: `docker logs traefik`
- System logs: `/var/log/syslog` or `journalctl -u docker`

### Useful Commands for Support

```bash
# System overview
docker-compose ps
docker stats --no-stream
df -h
free -h

# Configuration verification
docker-compose config
docker exec nexus env | grep NEXUS
```

## Prevention

### Regular Maintenance

```bash
# Weekly cleanup
make clean
docker system prune -f

# Update images
docker-compose pull
make restart

# Monitor disk usage
docker system df
```

### Monitoring

Consider implementing:

- Health checks for all services
- Log aggregation and monitoring
- Resource usage alerts
- Automated backups

### Best Practices

1. Always use version-pinned images in production
2. Regular security updates
3. Monitor resource usage
4. Implement proper backup strategies
5. Test disaster recovery procedures
6. Document any custom configurations

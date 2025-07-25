# Security Guide

This document outlines the security features and best practices implemented in this Nexus Docker setup.

## 🔐 Security Features

### Secure Credential Management

#### ❌ ELIMINATED: Default Passwords

- The dangerous `admin123` default password is no longer used
- Scripts will fail if secure credentials are not generated
- All deployment methods require explicit credential generation

#### ✅ IMPLEMENTED: Secure Password Generation

- Cryptographically secure random passwords (16 characters)
- Mixed case letters, numbers, and symbols
- Generated using OpenSSL for cryptographic security

### Credential Storage

**Files Created:**

- `.nexus-credentials` - Contains generated credentials (600 permissions)
- `.env` - Environment variables for docker-compose (600 permissions)

**Security Measures:**

- Files have restricted permissions (owner read/write only)
- Excluded from version control via `.gitignore`
- Clear warnings about not committing these files

### Environment Variable Protection

**Docker Compose Integration:**

- All sensitive values use environment variables
- Required variables fail fast if not set (`${VAR:?error}`)
- Default values only for non-sensitive configuration

## 🚨 Security Workflows

### Initial Setup (REQUIRED)

```bash
# 1. Generate secure credentials (REQUIRED)
make credentials

# 2. Start services (will fail without step 1)
make start

# 3. Complete setup
make setup
```

### Development Setup

```bash
# For developers
make dev-setup    # Sets up development environment
make credentials  # Generate secure credentials
make start        # Start with secure credentials
```

### Production Deployment

```bash
# 1. Generate production credentials
make credentials

# 2. Review and backup credentials
cat .nexus-credentials  # Review generated credentials
cp .nexus-credentials credentials.backup  # Backup securely

# 3. Deploy with secure credentials
make start
make setup
```

## 🛡️ Security Best Practices

### Credential Management

**✅ DO:**

- Always run `make credentials` before first deployment
- Store credentials in a secure password manager
- Use unique credentials for each environment
- Regularly rotate passwords
- Backup credentials securely before deployment

**❌ DON'T:**

- Use default passwords (`admin123`)
- Commit credential files to version control
- Share credentials in plain text
- Use the same credentials across environments
- Store credentials in unsecured locations

### File Permissions

The credential generation script automatically sets secure permissions:

```bash
chmod 600 .nexus-credentials  # Owner read/write only
chmod 600 .env               # Owner read/write only
```

### Network Security

**Internal Communication:**

- PostgreSQL accessible only within Docker network
- Nexus communicates with PostgreSQL via internal DNS

**External Access:**

- Only necessary ports exposed (8081, 8082, 8083)
- Consider using Traefik for SSL/TLS termination
- Implement firewall rules for production

### Container Security

**Image Security:**

- Using official Sonatype Nexus image
- PostgreSQL official image with version pinning
- Regular image updates recommended

**Runtime Security:**

- Containers run as non-root users where possible
- Read-only filesystem for configuration files
- Named volumes for data persistence

## 🔍 Security Validation

### Pre-commit Security Checks

Automated security scanning includes:

- **Secret detection** - Prevents committing passwords/keys
- **Private key detection** - Catches SSH keys, certificates
- **Credential file exclusion** - Ensures sensitive files aren't committed

### Manual Security Audit

```bash
# Check file permissions
ls -la .nexus-credentials .env

# Verify no credentials in git
git status --ignored

# Test credential loading
make start  # Should fail without credentials
make credentials && make start  # Should succeed
```

## 🚨 Incident Response

### Credential Compromise

If credentials are compromised:

1. **Immediate Actions:**

   ```bash
   make stop                    # Stop services
   rm .nexus-credentials .env   # Remove compromised credentials
   docker volume rm nexus_nexus-data  # Reset Nexus data (if needed)
   ```

2. **Generate New Credentials:**

   ```bash
   make credentials  # Generate new secure credentials
   make start        # Start with new credentials
   make setup        # Reconfigure
   ```

3. **Verify Security:**
   - Check access logs
   - Review user accounts in Nexus UI
   - Rotate any downstream credentials

### Unauthorized Access

If unauthorized access is detected:

1. **Assess Impact:**
   - Check Nexus access logs
   - Review repository access patterns
   - Identify affected repositories

2. **Secure Environment:**
   - Change all credentials immediately
   - Review and revoke API tokens
   - Check for unauthorized repositories/users

3. **Recovery:**
   - Audit repository contents
   - Scan for malicious packages
   - Implement additional monitoring

## 📋 Security Checklist

### Pre-Deployment

- [ ] Credentials generated with `make credentials`
- [ ] Credential files have correct permissions (600)
- [ ] No default passwords in configuration
- [ ] `.gitignore` excludes credential files
- [ ] SSL/TLS configured for production

### Post-Deployment

- [ ] Default admin password changed
- [ ] EULA accepted via secure API
- [ ] Repository tests pass
- [ ] Access logs monitored
- [ ] Backup procedures established

### Ongoing Security

- [ ] Regular credential rotation
- [ ] Security updates applied
- [ ] Access patterns monitored
- [ ] Vulnerability scanning enabled
- [ ] Incident response plan tested

## 🔧 Security Configuration

### Password Requirements

Generated passwords meet these requirements:

- **Length:** 16 characters minimum
- **Complexity:** Mixed case, numbers, symbols
- **Entropy:** Cryptographically secure random generation
- **Uniqueness:** Different password for each component

### Access Control

**Default Configuration:**

- Admin user: `admin`
- Database user: `nexus` (separate from admin)
- Application-specific passwords for each service

**Recommended Enhancements:**

- LDAP/Active Directory integration
- Role-based access control (RBAC)
- Multi-factor authentication (MFA)
- API token management

## 📞 Security Support

### Resources

- [Sonatype Security Documentation](https://help.sonatype.com/security)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)

### Reporting Security Issues

- Review code for security issues before committing
- Use pre-commit hooks to catch credentials
- Report vulnerabilities through proper channels
- Document security incidents for learning

## 🎯 Security Metrics

Track these security indicators:

- **Credential Age:** Days since last password rotation
- **Failed Login Attempts:** Monitor for brute force attacks
- **Repository Access Patterns:** Unusual download/upload activity
- **Certificate Validity:** SSL/TLS certificate expiration
- **Update Status:** Days since last security update

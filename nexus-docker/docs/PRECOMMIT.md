# Pre-commit Hooks and Code Quality

This repository uses [pre-commit](https://pre-commit.com/) to enforce code quality, security, and consistency standards.

## Quick Start

```bash
# Install pipenv (if not already installed)
pip3 install pipenv

# Setup development environment
make dev-setup
# or manually:
pipenv install --dev
pipenv run setup

# Run checks manually
make lint
# or with pipenv:
pipenv run lint
```

## What Gets Checked

### 🔍 **File Format & Syntax**

- **YAML/JSON/TOML/XML validation**: Ensures configuration files are properly formatted
- **Merge conflict detection**: Prevents committing files with merge markers
- **Large file detection**: Prevents files larger than 1MB from being committed
- **Symlink validation**: Checks for broken symbolic links

### 🧹 **Code Formatting**

- **Trailing whitespace removal**: Cleans up unnecessary whitespace
- **Line ending normalization**: Ensures consistent LF line endings
- **End-of-file fixes**: Adds newlines at end of files

### 🔒 **Security Scanning**

- **Private key detection**: Prevents accidental commit of SSH keys, certificates
- **AWS credentials detection**: Catches AWS access keys and secrets
- **Secret scanning**: Uses `detect-secrets` to find potential secrets
- **Baseline tracking**: Maintains `.secrets.baseline` for known acceptable "secrets"

### 🐚 **Shell Script Quality**

- **ShellCheck linting**: Comprehensive bash/sh script analysis
- **Executable permissions**: Ensures scripts have proper execute permissions
- **Syntax validation**: Catches common shell scripting errors

### 🐳 **Docker Best Practices**

- **Hadolint**: Dockerfile linting for security and best practices
- **docker-compose validation**: Ensures compose files are syntactically correct

### 📝 **Documentation Quality**

- **Markdown linting**: Consistent markdown formatting and style
- **Link validation**: Checks for broken internal links
- **Prettier formatting**: Auto-formats YAML and JSON files

### 🚫 **Repository Protection**

- **Branch protection**: Prevents direct commits to main/master branches
- **TODO/FIXME detection**: Ensures development comments are resolved
- **Commit message linting**: Enforces conventional commit standards

## Development Environment

This project uses **pipenv** for Python dependency management and virtual environment isolation.

### Why Pipenv

- **🔒 Reproducible builds**: `Pipfile.lock` ensures exact dependency versions
- **🏗️ Virtual environment isolation**: Prevents conflicts with system Python packages
- **📦 Simplified dependency management**: Easy to add/remove development tools
- **⚡ Built-in scripts**: Predefined commands for common tasks

### Pipenv Commands

```bash
# Activate virtual environment
pipenv shell

# Install dependencies
pipenv install --dev

# Run commands in virtual environment
pipenv run lint                 # Run linting
pipenv run setup               # Setup pre-commit hooks
pipenv run update-hooks        # Update hook versions
pipenv run check-secrets       # Update secrets baseline

# Add new dependencies
pipenv install --dev new-package

# Generate requirements.txt (if needed)
pipenv requirements --dev > requirements-dev.txt
```

### `.pre-commit-config.yaml`

Main configuration defining all hooks and their settings.

### `.secrets.baseline`

Baseline file for `detect-secrets` containing known acceptable patterns.

### `.markdownlint.yaml`

Configuration for markdown linting rules and exceptions.

## Running Checks

### Automatic (Recommended)

Pre-commit hooks run automatically on:

- **git commit**: Runs file validation, formatting, and security checks
- **git commit-msg**: Validates commit message format

### Manual Testing

```bash
# Run all hooks on all files
make lint

# Run specific hook
pre-commit run shellcheck --all-files
pre-commit run detect-secrets --all-files

# Run only on changed files
pre-commit run

# Skip hooks for urgent commits (not recommended)
git commit --no-verify -m "urgent fix"
```

## Common Workflows

### Initial Setup

```bash
# After cloning repository
cd nexus-docker
pip3 install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Run initial check
make lint
```

### Before Committing

```bash
# Check your changes
make lint

# If issues found, many are auto-fixed, so run again
make lint

# Commit when all checks pass
git add .
git commit -m "feat: add new functionality"
```

### Updating Hooks

```bash
# Update to latest hook versions
pre-commit autoupdate

# Test updated hooks
pre-commit run --all-files
```

## Troubleshooting

### Hook Installation Issues

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg

# Clear cache if needed
pre-commit clean
```

### ShellCheck Errors

```bash
# Common fixes:
# - Quote variables: "$variable" instead of $variable
# - Use [[ ]] instead of [ ] for conditions
# - Add shellcheck disable comments for false positives:
# shellcheck disable=SC2034
```

### Secrets Detection False Positives

```bash
# Add to .secrets.baseline
detect-secrets scan --update .secrets.baseline

# Or add inline comment to ignore
password="not-a-real-secret"  # pragma: allowlist secret
```

### Markdown Linting Issues

```bash
# Most issues are auto-fixed, but common manual fixes:
# - Use consistent header styles (# ## ###)
# - Fix line length issues
# - Add blank lines around code blocks
```

### Docker Compose Validation

```bash
# Test compose file manually
docker-compose -f nexus-docker/docker-compose.yml config

# Fix syntax errors shown in output
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Code Quality
on: [push, pull_request]
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install pre-commit
        run: pip install pre-commit
      - name: Run pre-commit
        run: pre-commit run --all-files
```

### Local Development Workflow

```bash
# 1. Make changes
vim nexus-docker/scripts/setup/setup-nexus.sh

# 2. Test locally
make lint

# 3. Fix any issues reported
# 4. Commit (hooks run automatically)
git add .
git commit -m "fix: improve error handling in setup script"

# 5. Push
git push
```

## Hook Details

### File Checks (`pre-commit-hooks`)

- Validates syntax of configuration files
- Prevents large files and merge conflicts
- Normalizes line endings and whitespace

### Security (`detect-secrets`)

- Scans for hardcoded passwords, API keys, tokens
- Uses entropy-based detection and regex patterns
- Maintains baseline of acceptable patterns

### Shell (`shellcheck-py`)

- Static analysis of shell scripts
- Catches common bugs and anti-patterns
- Enforces shell scripting best practices

### Docker (`hadolint`)

- Dockerfile security and optimization
- Best practice enforcement
- Image layer optimization suggestions

### Documentation (`markdownlint`, `prettier`)

- Consistent markdown formatting
- Table of contents validation
- Link checking and format standardization

## Benefits

1. **Consistency**: Uniform code style across all contributors
2. **Security**: Early detection of secrets and security issues
3. **Quality**: Automated catching of common bugs and issues
4. **Documentation**: Well-formatted and consistent documentation
5. **Efficiency**: Auto-fixing of many common issues
6. **Compliance**: Enforced standards for professional development

## Customization

You can modify `.pre-commit-config.yaml` to:

- Add new hooks
- Adjust hook arguments
- Exclude specific files or patterns
- Change hook versions

Always test changes with `pre-commit run --all-files` before committing configuration updates.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Comprehensive repository restructure for better organization
- Shared utilities in `scripts/common.sh`
- Enhanced Makefile with help and additional commands
- Comprehensive documentation in `docs/` directory
- Troubleshooting guide with detailed solutions
- Environment configuration template (`.env.example`)
- Script-specific README files for setup and testing
- Improved test coverage and error handling
- .gitignore for proper repository hygiene

### Changed

- Reorganized scripts into `scripts/setup/` and `scripts/testing/` directories
- Moved configuration files to `config/` directory
- Enhanced all test scripts with better error diagnostics
- Improved Docker registry testing with authentication
- Updated package selections for better compatibility

### Fixed

- NPM authentication format for scoped packages
- PyPI package compatibility issues with Python 3.13
- Docker registry connectivity and authentication
- EULA acceptance automation using official REST API
- All repository proxy tests now pass consistently

## [1.0.0] - 2025-01-XX

### Added

- Initial Docker Compose setup for Nexus Repository Manager
- PostgreSQL 17 backend integration
- Traefik reverse proxy with SSL support
- Automated repository provisioning
- Comprehensive test suite for all repository types
- EULA acceptance automation
- Docker registry proxy support

### Features

- Maven Central proxy repository
- NPM registry proxy
- PyPI proxy repository  
- Docker Hub proxy
- Automated SSL certificate generation
- Health checks and monitoring
- Backup and restore capabilities

### Technical

- Multi-stage container initialization
- Persistent data volumes
- Network isolation and security
- Resource optimization
- Cross-platform compatibility

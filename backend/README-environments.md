# Multi-Environment Configuration Guide

## Phase 1: Backend Environment Separation ✅

This update implements proper environment separation for the backend, allowing clean separation between development and production configurations.

## Environment Files

### Development Environment: `.env.dev`
- **GCP Project**: `pottery-app-456522`
- **Usage**: Local development and dev Cloud Run deployments
- **Firebase Project**: `pottery-app-456522`
- **Security**: Development-level settings, longer token expiration

### Production Environment: `.env.prod`
- **GCP Project**: `pottery-app-prod` (to be created)
- **Usage**: Production Cloud Run deployments
- **Firebase Project**: `pottery-app-prod` (to be created)
- **Security**: Production-hardened settings, shorter token expiration

### Legacy Support: `.env.local`
- **Status**: Maintained for backward compatibility
- **Usage**: Legacy local development workflows

## Usage Commands

### Local Development
```bash
# Use development environment (default)
./run_docker_local.sh

# Use development environment explicitly
./run_docker_local.sh --env=dev

# Use legacy local environment
./run_docker_local.sh --env=local

# Enable debugging
./run_docker_local.sh --debug
```

### Cloud Run Deployment
```bash
# Deploy to development environment (default)
./build_and_deploy.sh

# Deploy to development explicitly
./build_and_deploy.sh --env=dev

# Deploy to production
./build_and_deploy.sh --env=prod

# Get help
./build_and_deploy.sh --help
```

## Configuration Features

### Environment Detection
- `ENVIRONMENT` variable automatically set in runtime
- Backend can detect environment via `settings.is_development` and `settings.is_production`
- Debug mode automatically enabled in development

### Environment Isolation
- **Development**: Longer timeouts, debug logging, test credentials
- **Production**: Secure timeouts, warning-level logging, secure secrets

### Migration Path
- Existing `.env.local` continues to work via `--env=local`
- New projects should use `.env.dev` by default
- Production requires explicit `--env=prod` flag for safety

## Next Steps (Phase 2)

1. **Create production Firebase project** (`pottery-app-prod`)
2. **Set up frontend environment configuration**
3. **Configure CI/CD pipelines**
4. **Set up environment-specific secrets**

## File Structure
```
backend/
├── .env.dev          # Development environment
├── .env.prod         # Production environment
├── .env.local        # Legacy local development
├── config.py         # Updated with ENVIRONMENT support
├── run_docker_local.sh    # Updated with --env parameter
├── build_and_deploy.sh    # Updated with --env parameter
└── README-environments.md # This file
```

## Security Notes

- **Production secrets**: Never commit `.env.prod` with real secrets
- **Service accounts**: Use separate service accounts per environment
- **Firebase projects**: Keep dev and prod Firebase projects completely separate
- **Deployment keys**: Use different deployment credentials per environment

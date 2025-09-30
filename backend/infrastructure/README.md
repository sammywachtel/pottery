# Infrastructure as Code - GCS CORS Configuration

This directory contains infrastructure configuration files and scripts for managing Google Cloud Storage (GCS) bucket CORS settings as code.

## Problem Solved

Flutter web applications and other browser-based clients cannot display images from GCS buckets due to Cross-Origin Resource Sharing (CORS) restrictions. This infrastructure setup solves that problem by:

1. **Version Control**: CORS configurations are stored as JSON files in git
2. **Environment-Specific**: Different CORS rules for local development vs production
3. **Automated Deployment**: CORS setup integrated into existing deployment scripts
4. **Easy Management**: Simple commands to apply, check, and remove CORS rules

## Directory Structure

```
infrastructure/
├── README.md                    # This documentation
├── cors-config.json            # Default CORS configuration (permissive)
├── cors-config.local.json      # Local development CORS configuration
└── cors-config.prod.json       # Production CORS configuration
```

## CORS Configuration Files

### Local Development (`cors-config.local.json`)
- **Origins**: localhost on common ports (3000, 8000, 8080)
- **Cache**: 5 minutes (short for rapid development)
- **Headers**: Includes Authorization for authenticated requests

### Production (`cors-config.prod.json`)
- **Origins**: Specific production domains only
- **Cache**: 1 hour (longer for performance)
- **Headers**: Minimal set for security

### Default (`cors-config.json`)
- **Origins**: Wildcard (*) - use with caution
- **Cache**: 1 hour
- **Headers**: Standard image serving headers

## Usage

### Quick Start

```bash
# Set up CORS for local development
./scripts/manage-cors.sh apply local

# Check current CORS configuration
./scripts/manage-cors.sh status

# Set up CORS for production
./scripts/manage-cors.sh apply prod

# Remove all CORS rules
./scripts/manage-cors.sh remove
```

### Manual Commands

```bash
# Apply specific environment to specific bucket
./scripts/manage-cors.sh apply local my-bucket-name

# Check CORS for specific bucket
./scripts/manage-cors.sh status my-bucket-name

# Remove CORS from specific bucket
./scripts/manage-cors.sh remove my-bucket-name
```

### Integrated Setup

The CORS configuration is automatically applied when using existing workflows:

```bash
# Local development - includes CORS setup
./run_docker_local.sh

# Production deployment - includes CORS setup
./build_and_deploy.sh

# Manual infrastructure setup
./scripts/setup-infrastructure.sh local
```

## Configuration Details

### HTTP Methods Allowed
- `GET` - Required for image downloads
- `HEAD` - Required for metadata checks

### Response Headers Exposed
- `Content-Type` - Image MIME type
- `Content-Length` - File size
- `Content-Range` - For partial content
- `ETag` - Caching validation
- `Cache-Control` - Caching directives
- `Last-Modified` - Modification timestamp
- `Accept-Ranges` - Range request support

### Cache Settings
- **Local**: 300 seconds (5 minutes) for rapid development
- **Production**: 3600 seconds (1 hour) for performance

## Environment Variables Required

The scripts automatically load configuration from:
- `.env.local` (for local development)
- `.env.deploy` (for deployment)

Required variables:
- `GCP_PROJECT_ID` - Google Cloud project ID
- `GCS_BUCKET_NAME` - Target storage bucket name

## Prerequisites

1. **Google Cloud SDK**: Install and authenticate
   ```bash
   gcloud auth login
   gcloud config set project your-project-id
   ```

2. **Permissions**: Your account/service account needs:
   - `Storage Admin` or `Storage Object Admin` role
   - Access to the target GCS bucket

3. **Environment Files**: Ensure `.env.local` or `.env.deploy` exists with required variables

## Troubleshooting

### CORS Not Taking Effect
- Browser cache: Hard refresh (Ctrl+F5) or use incognito mode
- CDN cache: If using a CDN, clear its cache
- Verify configuration: Use `./scripts/manage-cors.sh status` to confirm

### Authentication Errors
```bash
# Check current authentication
gcloud auth list

# Re-authenticate if needed
gcloud auth login

# Check project setting
gcloud config get-value project
```

### Bucket Access Errors
```bash
# Test bucket access
gsutil ls gs://your-bucket-name

# Check bucket permissions
gsutil iam get gs://your-bucket-name
```

### Flutter Web Still Can't Load Images
1. Verify CORS is applied: `./scripts/manage-cors.sh status`
2. Check browser console for specific CORS errors
3. Ensure Flutter app uses correct signed URLs
4. Test with curl to isolate the issue:
   ```bash
   curl -H "Origin: http://localhost:3000" -I "https://storage.googleapis.com/your-bucket/test-image.jpg"
   ```

## Extending Configuration

### Adding New Environments

1. Create new configuration file:
   ```bash
   cp infrastructure/cors-config.local.json infrastructure/cors-config.staging.json
   ```

2. Update origins in the new file:
   ```json
   {
     "origin": ["https://staging.pottery-app.com"],
     ...
   }
   ```

3. The `manage-cors.sh` script will automatically support the new environment:
   ```bash
   ./scripts/manage-cors.sh apply staging
   ```

### Adding New Origins

Edit the appropriate configuration file and add new origins to the `origin` array:

```json
{
  "origin": [
    "https://pottery-app.com",
    "https://www.pottery-app.com",
    "https://app.pottery-app.com",
    "https://new-domain.com"
  ],
  ...
}
```

### Custom Response Headers

Add headers to the `responseHeader` array as needed:

```json
{
  "responseHeader": [
    "Content-Type",
    "Content-Length",
    "Custom-Header",
    "Another-Header"
  ],
  ...
}
```

## Integration with CI/CD

The infrastructure setup is integrated into existing deployment workflows:

### Local Development
- `./run_docker_local.sh` automatically applies local CORS configuration
- No manual intervention required for developers

### Production Deployment
- `./build_and_deploy.sh` automatically applies production CORS configuration
- Ensures production deployment includes infrastructure setup

### Manual Infrastructure Management
- `./scripts/setup-infrastructure.sh` for one-time setup
- `./scripts/manage-cors.sh` for fine-grained control

## Security Considerations

### Production Configuration
- ✅ **Specific Origins**: Only allow your actual domains
- ✅ **Minimal Headers**: Only expose necessary headers
- ✅ **Appropriate Cache**: Balance performance vs flexibility

### Development Configuration
- ⚠️ **Localhost Origins**: More permissive for development ease
- ⚠️ **Additional Headers**: May include debugging headers

### Default Configuration
- ❌ **Wildcard Origin**: Should only be used for testing
- ❌ **Not for Production**: Too permissive for production use

## Monitoring and Maintenance

### Regular Tasks
1. **Review CORS Logs**: Check GCS access logs for CORS-related errors
2. **Update Origins**: Add new domains as the application grows
3. **Security Audit**: Regularly review allowed origins and headers

### Performance Monitoring
- Monitor cache hit rates
- Adjust `maxAgeSeconds` based on usage patterns
- Consider CDN integration for global performance

This infrastructure-as-code approach ensures consistent, repeatable, and version-controlled CORS configuration management across all environments.

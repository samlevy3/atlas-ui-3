# Deploying Atlas UI to Cloud.gov

This guide covers deploying Atlas UI to [cloud.gov](https://cloud.gov), a FedRAMP-authorized Platform-as-a-Service based on Cloud Foundry.

## Prerequisites

1. **Cloud.gov Account**: You need an active cloud.gov account with an organization and space.
2. **CF CLI**: Install the [Cloud Foundry CLI](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html).
3. **Login to cloud.gov**:
   ```bash
   cf login -a api.fr.cloud.gov --sso
   ```

## Configuration Files

The deployment uses these files:

| File | Purpose |
|------|---------|
| `manifest.yml` | Cloud Foundry deployment configuration |
| `Procfile` | Specifies the startup command |
| `runtime.txt` | Specifies Python version |
| `.profile` | Pre-start script for directory setup |

## Pre-Deployment Setup

### 1. Build the Frontend Locally

The multi-buildpack approach builds the frontend during deployment, but you can also pre-build:

```bash
cd frontend
npm install
npm run build
cd ..
```

### 2. Configure Environment Variables

Update `manifest.yml` with your API keys and configuration. For sensitive values, use cloud.gov user-provided services:

```bash
# Create a user-provided service for secrets
cf cups atlas-secrets -p '{"OPENAI_API_KEY":"sk-xxx","ANTHROPIC_API_KEY":"xxx"}'
```

Then uncomment the `services` section in `manifest.yml`:
```yaml
services:
  - atlas-secrets
```

### 3. Configure S3 Storage (Optional)

If you need S3 storage for file uploads:

```bash
# Create S3 service
cf create-service s3 basic atlas-s3-bucket

# Bind to your app (or add to manifest.yml services section)
cf bind-service atlas-ui atlas-s3-bucket
```

Update your environment variables to use the bound service credentials (available via `VCAP_SERVICES`).

## Deployment

### Quick Deploy

```bash
cf push
```

### Deploy with Specific Settings

```bash
# Deploy with more memory
cf push -m 2G

# Deploy without starting (for configuration)
cf push --no-start

# Set environment variables
cf set-env atlas-ui OPENAI_API_KEY "sk-xxx"
cf set-env atlas-ui LOG_LEVEL "DEBUG"

# Start the app
cf start atlas-ui
```

### View Logs

```bash
# Recent logs
cf logs atlas-ui --recent

# Stream logs
cf logs atlas-ui
```

## Environment Variables

### Required Variables

Set these in `manifest.yml` or via `cf set-env`:

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI API key (or other LLM provider keys) |
| `DEBUG_MODE` | Set to `false` for production |
| `LOG_LEVEL` | Logging level (`INFO` recommended) |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FEATURE_TOOLS_ENABLED` | `true` | Enable MCP tools |
| `FEATURE_AGENT_MODE_AVAILABLE` | `true` | Enable agent mode |
| `FEATURE_MARKETPLACE_ENABLED` | `false` | Enable marketplace |
| `BACKEND_PUBLIC_URL` | - | Public URL for file access |

## Using Secrets (Recommended)

For production, avoid putting secrets in `manifest.yml`. Use user-provided services:

```bash
# Create secrets service
cf cups atlas-secrets -p '{
  "OPENAI_API_KEY": "sk-xxx",
  "ANTHROPIC_API_KEY": "xxx",
  "CAPABILITY_TOKEN_SECRET": "your-secret"
}'

# The app reads these from VCAP_SERVICES
```

Update your code or add environment parsing to read from `VCAP_SERVICES`.

## Scaling

```bash
# Scale instances
cf scale atlas-ui -i 3

# Scale memory
cf scale atlas-ui -m 2G

# Scale disk
cf scale atlas-ui -k 4G
```

## Custom Domain (Optional)

```bash
# Map a custom domain
cf map-route atlas-ui your-domain.gov --hostname atlas

# Or update manifest.yml with routes
```

## Troubleshooting

### App Crashes on Start

1. Check logs: `cf logs atlas-ui --recent`
2. Verify Python version in `runtime.txt`
3. Ensure all dependencies are in `requirements.txt`

### Frontend Not Loading

1. Verify frontend build completed: check for `frontend/dist` directory
2. Check that static files are being served correctly

### Memory Issues

Increase memory in `manifest.yml` or via:
```bash
cf scale atlas-ui -m 2G
```

### Port Binding

Cloud Foundry sets the `PORT` environment variable automatically. The app binds to `0.0.0.0:$PORT`.

## CI/CD Integration

For automated deployments, you can use the CF CLI in your CI pipeline:

```yaml
# Example GitHub Actions step
- name: Deploy to cloud.gov
  run: |
    cf login -a api.fr.cloud.gov -u ${{ secrets.CF_USERNAME }} -p ${{ secrets.CF_PASSWORD }} -o your-org -s your-space
    cf push
```

## Security Considerations

1. **Never commit secrets** to `manifest.yml` - use user-provided services
2. Set `DEBUG_MODE=false` in production
3. Configure proper CSP headers via `SECURITY_CSP_VALUE`
4. Enable `FEATURE_DOMAIN_WHITELIST_ENABLED` if needed
5. Review and configure `FEATURE_PROXY_SECRET_ENABLED` for authentication

## Support

For cloud.gov-specific issues, see [cloud.gov documentation](https://cloud.gov/docs/).
For Atlas UI issues, see the project README.

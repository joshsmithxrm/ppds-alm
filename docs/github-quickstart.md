# GitHub Actions Quickstart

This guide shows you how to use PPDS ALM reusable workflows in your GitHub Actions pipelines.

## Prerequisites

1. A GitHub repository with your Dataverse solution
2. An Azure AD app registration for authentication
3. Repository secrets configured (see [Authentication](./authentication.md))

## Available Workflows

| Workflow | Description |
|----------|-------------|
| `plugin-deploy.yml` | Deploy plugins to Dataverse |
| `plugin-extract.yml` | Extract plugin registrations from assembly |
| `solution-export.yml` | Export solution from Dataverse |
| `solution-import.yml` | Import solution to Dataverse |
| `full-alm.yml` | Complete ALM pipeline |

## Quick Start

### 1. Configure Repository Secrets

Go to **Settings > Secrets and variables > Actions** and add:

- `DATAVERSE_CLIENT_ID` - Azure AD app client ID
- `DATAVERSE_CLIENT_SECRET` - Azure AD app client secret
- `DATAVERSE_TENANT_ID` - Azure AD tenant ID

### 2. Create a Workflow File

Create `.github/workflows/deploy.yml` in your repository:

```yaml
name: Deploy Plugins

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1
    with:
      environment-url: 'https://myorg.crm.dynamics.com'
      registration-file: './src/Plugins/registrations.json'
      detect-drift: true
    secrets:
      client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
      client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
      tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

### 3. Run the Workflow

Push to main or manually trigger the workflow from the Actions tab.

## Example Workflows

### Extract Plugin Registrations

```yaml
name: Extract Registrations

on:
  workflow_dispatch:

jobs:
  extract:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-extract.yml@v1
    with:
      assembly-path: './src/Plugins/bin/Release/net462/MyPlugins.dll'
      output-path: './src/Plugins/registrations.json'
```

### Export Solution

```yaml
name: Nightly Export

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily

jobs:
  export:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-export.yml@v1
    with:
      environment-url: 'https://myorg-dev.crm.dynamics.com'
      solution-name: 'MySolution'
      managed: false
    secrets:
      client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
      client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
      tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

### Full ALM Pipeline

```yaml
name: Release Pipeline

on:
  release:
    types: [published]

jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/full-alm.yml@v1
    with:
      source-environment-url: 'https://myorg-dev.crm.dynamics.com'
      target-environment-url: 'https://myorg.crm.dynamics.com'
      solution-name: 'MySolution'
      deploy-managed: true
      deploy-plugins: true
    secrets:
      source-client-id: ${{ secrets.DEV_CLIENT_ID }}
      source-client-secret: ${{ secrets.DEV_CLIENT_SECRET }}
      source-tenant-id: ${{ secrets.TENANT_ID }}
      target-client-id: ${{ secrets.PROD_CLIENT_ID }}
      target-client-secret: ${{ secrets.PROD_CLIENT_SECRET }}
      target-tenant-id: ${{ secrets.TENANT_ID }}
```

## Workflow Inputs Reference

### plugin-deploy.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment-url` | Yes | - | Dataverse environment URL |
| `registration-file` | No | `./registrations.json` | Path to registrations JSON |
| `detect-drift` | No | `true` | Run drift detection |
| `working-directory` | No | `.` | Working directory |

### plugin-extract.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `assembly-path` | Yes | - | Path to plugin DLL |
| `output-path` | No | `./registrations.json` | Output file path |
| `working-directory` | No | `.` | Working directory |

### solution-export.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment-url` | Yes | - | Source environment URL |
| `solution-name` | Yes | - | Solution unique name |
| `output-path` | No | `./solutions` | Output directory |
| `managed` | No | `false` | Export as managed |
| `working-directory` | No | `.` | Working directory |

### solution-import.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment-url` | Yes | - | Target environment URL |
| `solution-file` | Yes | - | Path to solution zip |
| `publish-changes` | No | `true` | Publish after import |
| `activate-plugins` | No | `true` | Activate plugin steps |
| `overwrite-unmanaged` | No | `false` | Overwrite customizations |
| `working-directory` | No | `.` | Working directory |

## Version Tags

Use specific version tags to ensure stability:

- `@v1` - Latest v1.x release (recommended)
- `@v1.0.0` - Specific version
- `@main` - Latest development (not recommended for production)

## Troubleshooting

### Common Issues

**Authentication Failed**
- Verify your secrets are correctly configured
- Ensure the app registration has proper permissions
- Check the environment URL is correct

**Module Not Found**
- The workflows automatically install PPDS.Tools
- Check PowerShell Gallery is accessible from GitHub runners

**Solution Import Failed**
- Check for missing dependencies
- Verify the solution is compatible with the target environment

See [Troubleshooting](./troubleshooting.md) for more help.

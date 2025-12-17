# Authentication Guide

This guide explains how to set up authentication for PPDS ALM pipelines.

## Overview

PPDS ALM uses service principals (app registrations) to authenticate with Power Platform environments. This provides:

- **Non-interactive authentication** for CI/CD pipelines
- **Scoped permissions** without user credentials
- **Audit trail** of automated actions
- **Secret rotation** capability

## Prerequisites

- Azure AD access (to create app registrations)
- Power Platform Admin Center access (to create application users)
- Repository admin access (to configure secrets)

## Step 1: Create App Registration

### Azure Portal

1. Go to [Azure Portal](https://portal.azure.com) > Azure Active Directory
2. Select **App registrations** > **New registration**
3. Configure:
   - **Name:** `Power Platform CI/CD` (or your preferred name)
   - **Supported account types:** Single tenant
   - **Redirect URI:** Leave blank
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID**

### Create Client Secret

1. In your app registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Add a description: `CI/CD Pipeline`
4. Choose expiration: 6 months, 12 months, or 24 months
5. Click **Add**
6. **IMPORTANT:** Copy the secret **value** immediately (it won't be shown again)

### Azure CLI Alternative

```bash
# Create app registration
az ad app create --display-name "Power Platform CI/CD"

# Get app ID
APP_ID=$(az ad app list --display-name "Power Platform CI/CD" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Create client secret (expires in 1 year)
az ad app credential reset --id $APP_ID --years 1
```

## Step 2: Create Application User in Power Platform

The app registration must be added as an application user in each target environment.

### Power Platform Admin Center

1. Go to [Power Platform Admin Center](https://admin.powerplatform.microsoft.com)
2. Select **Environments** > Select your environment
3. Go to **Settings** > **Users + permissions** > **Application users**
4. Click **+ New app user**
5. Click **+ Add an app** and search for your app registration
6. Select your **Business unit** (usually the root)
7. Under **Security roles**, select:
   - **System Administrator** for full access, OR
   - Custom role with required permissions
8. Click **Create**

### Repeat for Each Environment

Create application users in all environments:
- Dev environment
- QA environment
- Prod environment (when ready)

### PAC CLI Alternative

```bash
pac admin assign-user \
  --environment "https://myorg-dev.crm.dynamics.com" \
  --user "<app-id>" \
  --role "System Administrator"
```

## Step 3: Configure Repository Secrets

### GitHub Actions

#### Using GitHub Environments (Recommended)

1. Go to repository **Settings** > **Environments**
2. Create environments: `Dev`, `QA`, `Prod`
3. For each environment, add:

**Variables:**
| Name | Description | Example |
|------|-------------|---------|
| `POWERPLATFORM_ENVIRONMENT_URL` | Environment URL | `https://myorg-qa.crm.dynamics.com/` |
| `POWERPLATFORM_TENANT_ID` | Azure AD tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `POWERPLATFORM_CLIENT_ID` | App registration client ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

**Secrets:**
| Name | Description |
|------|-------------|
| `POWERPLATFORM_CLIENT_SECRET` | App registration client secret |

#### Using Repository Secrets (Legacy/Simple Setup)

If not using environments:

1. Go to repository **Settings** > **Secrets and variables** > **Actions**
2. Add secrets:
   - `DATAVERSE_DEV_URL`
   - `DATAVERSE_QA_URL`
   - `DATAVERSE_PROD_URL`
   - `DATAVERSE_TENANT_ID`
   - `DATAVERSE_CLIENT_ID`
   - `DATAVERSE_CLIENT_SECRET`

#### Workflow Usage

```yaml
jobs:
  deploy:
    environment: QA  # Uses QA environment secrets
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v1
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

### Azure DevOps

#### Service Connection (Recommended)

1. Go to **Project Settings** > **Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Fill in:
   - Server URL: Environment URL
   - Tenant ID: Azure AD tenant ID
   - Application ID: App registration client ID
   - Client Secret: App registration secret
5. Name it descriptively: `Dataverse-QA`
6. Click **Save**

#### Variable Groups

For custom scripts:

1. Go to **Pipelines** > **Library**
2. Create variable groups: `PowerPlatform-Dev`, `PowerPlatform-QA`, `PowerPlatform-Prod`
3. Add variables (mark secrets appropriately):
   - `EnvironmentUrl`
   - `TenantId`
   - `ClientId`
   - `ClientSecret` (secret)

## Security Best Practices

### Principle of Least Privilege

| Environment | Recommended Role |
|-------------|------------------|
| Dev | System Administrator |
| QA | System Customizer + Solution import |
| Prod | Custom role (minimal permissions) |

### Production Custom Role

For production, create a custom security role with only:
- Solution: Read, Write (import)
- Plugin Assembly: Create, Read, Write, Delete
- Plugin Step: Create, Read, Write, Delete
- Customization: Publish All
- System Job: Read (monitoring)

### Secret Rotation

1. Create new secret before old one expires
2. Update GitHub/Azure DevOps secrets
3. Verify pipelines still work
4. Delete old secret

**Recommended schedule:** Every 6-12 months

### Monitoring

Monitor service principal usage:
1. Azure AD > App registrations > Sign-in logs
2. Power Platform Admin Center > Analytics > Activity logging

## Troubleshooting

### "AADSTS700016: Application not found"

- Verify Client ID is correct
- Ensure app registration is in the correct tenant
- Check for typos

### "AADSTS7000215: Invalid client secret"

- Verify you're using the secret **value**, not **ID**
- Check if secret has expired
- Create a new secret and update configuration

### "User is not a member of the organization"

- Application user doesn't exist in Dataverse
- Create application user in Power Platform Admin Center
- Ensure correct Business Unit

### "Insufficient privileges"

- Check security roles assigned to application user
- Ensure solution import permissions are granted
- Consider using System Administrator for troubleshooting

## Verification

Test authentication before using in pipelines:

### PAC CLI

```bash
# Create auth profile
pac auth create \
  --environment "https://myorg.crm.dynamics.com" \
  --tenant "<tenant-id>" \
  --applicationId "<client-id>" \
  --clientSecret "<client-secret>"

# Test by listing solutions
pac solution list
```

### PowerShell (PPDS.Tools)

```powershell
# Install module
Install-Module PPDS.Tools -Force

# Connect
Connect-DataverseEnvironment `
  -EnvironmentUrl "https://myorg.crm.dynamics.com" `
  -TenantId "<tenant-id>" `
  -ClientId "<client-id>" `
  -ClientSecret "<client-secret>"

# Test connection
Get-DataversePluginAssembly | Select-Object Name -First 5
```

## Multi-Environment Configuration

### Configuration File Pattern

Create deployment settings for each environment:

```
config/
├── MySolution.dev.deploymentsettings.json
├── MySolution.qa.deploymentsettings.json
└── MySolution.prod.deploymentsettings.json
```

### Connection Reference Mapping

Example deployment settings:
```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "new_ApiEndpoint",
      "Value": "https://qa-api.example.com"
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "new_sharedcommondataserviceforapps_abc123",
      "ConnectionId": "shared-commondata-qa-connection-id"
    }
  ]
}
```

## See Also

- [GitHub Actions Quickstart](./github-quickstart.md)
- [Azure DevOps Quickstart](./azure-devops-quickstart.md)
- [Troubleshooting](./troubleshooting.md)
- [Microsoft Authentication Documentation](https://learn.microsoft.com/en-us/power-platform/alm/devops-build-tools#configure-service-connections)

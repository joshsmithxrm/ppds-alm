# Authentication Guide

This guide explains how to set up authentication for PPDS ALM workflows and templates.

## Overview

PPDS ALM uses Azure AD app registrations to authenticate with Dataverse environments. This approach:

- Works in unattended CI/CD scenarios
- Supports least-privilege access
- Is recommended by Microsoft for ALM scenarios

## Azure AD App Registration Setup

### 1. Create the App Registration

1. Go to [Azure Portal](https://portal.azure.com) > **Azure Active Directory** > **App registrations**
2. Click **New registration**
3. Enter a name (e.g., "PPDS ALM - Dev", "PPDS ALM - Prod")
4. Select **Accounts in this organizational directory only**
5. Leave Redirect URI blank
6. Click **Register**

### 2. Create a Client Secret

1. In your app registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Enter a description and expiration period
4. Click **Add**
5. **Copy the secret value immediately** - you won't be able to see it again

### 3. Grant API Permissions

1. Go to **API permissions**
2. Click **Add a permission**
3. Select **Dynamics CRM**
4. Select **Delegated permissions**
5. Check **user_impersonation**
6. Click **Add permissions**
7. Click **Grant admin consent** (requires admin rights)

### 4. Create Application User in Dataverse

1. Go to your Power Platform Admin Center
2. Select your environment
3. Click **Settings** > **Users + permissions** > **Application users**
4. Click **New app user**
5. Select your app registration
6. Assign a security role (e.g., "System Administrator" for full access)
7. Click **Create**

## Required Values

After setup, you'll need these values:

| Value | Where to Find |
|-------|---------------|
| Client ID | App registration > Overview > Application (client) ID |
| Client Secret | The value you copied when creating the secret |
| Tenant ID | App registration > Overview > Directory (tenant) ID |
| Environment URL | Power Platform Admin Center > Environment > Environment URL |

## Configuring GitHub Actions

### Repository Secrets

1. Go to your GitHub repository
2. Navigate to **Settings > Secrets and variables > Actions**
3. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| `DATAVERSE_CLIENT_ID` | Your app's Client ID |
| `DATAVERSE_CLIENT_SECRET` | Your app's Client Secret |
| `DATAVERSE_TENANT_ID` | Your Azure AD Tenant ID |

### Using in Workflows

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1
    with:
      environment-url: 'https://myorg.crm.dynamics.com'
    secrets:
      client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
      client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
      tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

### Multi-Environment Setup

For separate dev/test/prod environments, create separate secrets:

| Secret | Description |
|--------|-------------|
| `DEV_CLIENT_ID` | Dev environment client ID |
| `DEV_CLIENT_SECRET` | Dev environment client secret |
| `TEST_CLIENT_ID` | Test environment client ID |
| `TEST_CLIENT_SECRET` | Test environment client secret |
| `PROD_CLIENT_ID` | Production environment client ID |
| `PROD_CLIENT_SECRET` | Production environment client secret |
| `TENANT_ID` | Shared tenant ID (if same tenant) |

## Configuring Azure DevOps

### Option 1: Power Platform Service Connection

1. Go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Fill in:
   - **Server URL**: Your environment URL
   - **Tenant ID**: Your Azure AD tenant ID
   - **Application ID**: Your app's Client ID
   - **Client secret**: Your app's Client Secret
5. Name it descriptively (e.g., "Dataverse Dev")
6. Click **Save**

### Option 2: Azure Resource Manager Connection

1. Go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Azure Resource Manager**
4. Select **Service principal (manual)**
5. Fill in:
   - **Subscription ID**: Your Azure subscription
   - **Subscription Name**: Any name
   - **Service Principal ID**: Your app's Client ID
   - **Service Principal Key**: Your app's Client Secret
   - **Tenant ID**: Your Azure AD tenant ID
6. Click **Verify and save**

### Using in Pipelines

```yaml
stages:
  - template: azure-devops/templates/plugin-deploy.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg.crm.dynamics.com'
      serviceConnection: 'Dataverse Prod'  # Name of your service connection
```

## Security Best Practices

### Principle of Least Privilege

Create separate app registrations for different environments:

| Environment | Recommended Role |
|-------------|-----------------|
| Development | System Administrator |
| Test | System Customizer |
| Production | Custom role with minimal permissions |

### Custom Security Role

For production, create a custom security role with only:

- Plugin Assembly: Create, Read, Write, Delete
- Plugin Step: Create, Read, Write, Delete
- Solution: Read (for solution import)
- System Jobs: Read (for monitoring)

### Secret Rotation

1. **Set expiration reminders** for client secrets
2. **Rotate secrets regularly** (every 6-12 months)
3. **Use Azure Key Vault** for enterprise scenarios
4. **Monitor for secret exposure** in repository scans

### Separate Credentials per Environment

- Never use production credentials in dev/test
- Use separate app registrations per environment
- Different people can manage different credentials

## Troubleshooting

### "AADSTS700016: Application not found"

- Verify the Client ID is correct
- Ensure the app registration exists in the correct tenant

### "The user is not a member of the organization"

- The application user hasn't been created in Dataverse
- Create the application user in the Power Platform Admin Center

### "Insufficient privileges"

- The application user doesn't have the required security role
- Assign appropriate security roles to the application user

### "Invalid client secret"

- The secret may have expired
- Verify you're using the secret **value**, not the secret **ID**
- Create a new secret if needed

## Additional Resources

- [Microsoft: Use service principal authentication](https://learn.microsoft.com/en-us/power-platform/alm/devops-build-tools#create-service-principal-and-client-secret-using-the-power-platform-admin-center)
- [Microsoft: Application user management](https://learn.microsoft.com/en-us/power-platform/admin/manage-application-users)
- [Power Platform ALM documentation](https://learn.microsoft.com/en-us/power-platform/alm/)

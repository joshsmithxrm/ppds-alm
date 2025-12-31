# Azure OIDC Setup for GitHub Actions

This guide explains how to configure Azure authentication for GitHub Actions workflows using OpenID Connect (OIDC) federated credentials. This is required for workflows that deploy Azure resources (e.g., `azure-deploy.yml`).

---

## Overview

OIDC federation allows GitHub Actions to authenticate to Azure **without storing secrets**. Instead of a client secret, GitHub presents a token that Azure trusts based on the repository and environment.

### Benefits

| Benefit | Description |
|---------|-------------|
| No secret rotation | No client secrets to expire or rotate |
| Scoped access | Tokens are scoped to specific repos/environments |
| Audit trail | Azure logs show exactly which workflow authenticated |
| Zero secrets | Nothing sensitive stored in GitHub |

### How It Works

```
GitHub Actions                          Azure
     │                                    │
     ├─── 1. Request OIDC token ──────────┤
     │    (includes repo, environment)    │
     │                                    │
     ├─── 2. Present token to Azure ──────┤
     │                                    │
     │    3. Azure validates token ◄──────┤
     │       against federated credential │
     │                                    │
     ├─── 4. Receive access token ────────┤
     │                                    │
     └─── 5. Call Azure APIs ─────────────┘
```

---

## Prerequisites

- Azure subscription with Owner or User Access Administrator role
- Azure CLI installed and authenticated (`az login`)
- GitHub repository with admin access
- GitHub environments created (dev, qa, prod)

---

## Step 1: Create App Registration

Create an Azure AD application that will represent your GitHub Actions workflows.

### Azure Portal

1. Go to [Azure Portal](https://portal.azure.com) > **Microsoft Entra ID**
2. Select **App registrations** > **New registration**
3. Configure:
   - **Name:** `spn-github-{repo-name}` (e.g., `spn-github-myproject`)
   - **Supported account types:** Single tenant
   - **Redirect URI:** Leave blank
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID**

### Azure CLI

```bash
# Create app registration
az ad app create --display-name "spn-github-{repo-name}"

# Get the app ID for subsequent commands
APP_ID=$(az ad app list --display-name "spn-github-{repo-name}" --query "[0].appId" -o tsv)
echo "Application ID: $APP_ID"
```

---

## Step 2: Create Service Principal

The service principal is the security identity used for role assignments.

### Azure CLI

```bash
# Create service principal from app registration
az ad sp create --id $APP_ID

# Verify creation
az ad sp show --id $APP_ID --query "{appId:appId,displayName:displayName}" -o json
```

---

## Step 3: Configure Federated Credentials

Create a federated credential for **each GitHub environment** that will authenticate to Azure.

### Understanding the Subject Claim

The `subject` field must exactly match what GitHub sends:

| Scenario | Subject Format |
|----------|----------------|
| Environment | `repo:{owner}/{repo}:environment:{environment}` |
| Branch | `repo:{owner}/{repo}:ref:refs/heads/{branch}` |
| Tag | `repo:{owner}/{repo}:ref:refs/tags/{tag}` |
| Pull Request | `repo:{owner}/{repo}:pull_request` |

### Azure CLI

Create credentials for each environment (dev, qa, prod):

```bash
# Variables - customize these
APP_ID="<your-app-id>"
GITHUB_ORG="<github-org-or-username>"
GITHUB_REPO="<repo-name>"

# Dev environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':environment:dev",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# QA environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-qa",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':environment:qa",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Prod environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-prod",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':environment:prod",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Verify Credentials

```bash
az ad app federated-credential list --id $APP_ID --query "[].{name:name,subject:subject}" -o table
```

Expected output:

```
Name         Subject
-----------  ---------------------------------------------
github-dev   repo:myorg/myrepo:environment:dev
github-qa    repo:myorg/myrepo:environment:qa
github-prod  repo:myorg/myrepo:environment:prod
```

---

## Step 4: Assign Azure Roles

Grant the service principal permissions to manage Azure resources.

### Subscription-Level Contributor

For full resource deployment capabilities:

```bash
SUBSCRIPTION_ID="<your-subscription-id>"

az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### Resource Group-Level (More Restrictive)

For scoped access to specific resource groups:

```bash
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-myproject-dev
```

### Verify Role Assignment

```bash
az role assignment list \
  --assignee $APP_ID \
  --query "[].{role:roleDefinitionName,scope:scope}" \
  -o table
```

---

## Step 5: Configure GitHub Repository

### Create Environments

If environments don't exist:

```bash
gh api repos/{owner}/{repo}/environments/dev -X PUT
gh api repos/{owner}/{repo}/environments/qa -X PUT
gh api repos/{owner}/{repo}/environments/prod -X PUT
```

### Add Repository Variables

These values are **not secrets** - they're configuration identifiers:

```bash
gh variable set AZURE_CLIENT_ID --body "<application-client-id>"
gh variable set AZURE_TENANT_ID --body "<directory-tenant-id>"
gh variable set AZURE_SUBSCRIPTION_ID --body "<subscription-id>"
```

### Verify Configuration

```bash
gh variable list
```

---

## Step 6: Workflow Configuration

### Using OIDC in Workflows

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev  # Must match federated credential subject

    permissions:
      id-token: write  # Required for OIDC
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Resources
        run: |
          az group create --name rg-myproject-dev --location eastus
```

### Passing to Reusable Workflows

When calling reusable workflows, pass the OIDC identifiers via the `with` block:

```yaml
jobs:
  deploy-infrastructure:
    uses: org/alm-repo/.github/workflows/azure-deploy.yml@v1
    with:
      environment: dev
      resource-group: rg-myproject-dev
      app-name-prefix: myproject
      # Pass identifiers as inputs, not secrets
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

---

## Troubleshooting

### "AADSTS70021: No matching federated identity record found"

**Cause:** The subject claim from GitHub doesn't match any federated credential.

**Solution:**
1. Verify the workflow uses `environment:` that matches the credential
2. Check subject format is exactly `repo:{owner}/{repo}:environment:{env}`
3. Environment names are case-sensitive

```bash
# List credentials to verify
az ad app federated-credential list --id $APP_ID -o table
```

### "MissingSubscription" Error in Git Bash (Windows)

**Cause:** Git Bash converts Unix-style paths (`/subscriptions/...`) to Windows paths.

**Solution:** Set `MSYS_NO_PATHCONV=1` before the command:

```bash
MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

Or use PowerShell/CMD instead of Git Bash for Azure CLI commands.

### "Authorization_RequestDenied"

**Cause:** Insufficient permissions to create app registrations or role assignments.

**Solution:**
- App registration: Requires Application Administrator or Global Administrator
- Role assignment: Requires Owner or User Access Administrator on the scope

### Workflow Fails with "OIDC token could not be retrieved"

**Cause:** Missing `id-token: write` permission.

**Solution:** Add permissions block to job:

```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
```

---

## Security Best Practices

### Principle of Least Privilege

| Environment | Recommended Scope |
|-------------|-------------------|
| Dev | Subscription Contributor (flexibility) |
| QA | Resource Group Contributor (scoped) |
| Prod | Resource Group Contributor + approval gates |

### Environment Protection Rules

Configure in GitHub repository settings:

| Environment | Protection |
|-------------|------------|
| dev | None (auto-deploy) |
| qa | None or required reviewers |
| prod | Required reviewers + wait timer |

### Separate Service Principals

For high-security scenarios, use separate app registrations per environment:

| Environment | App Registration |
|-------------|------------------|
| dev | `spn-github-myproject-dev` |
| qa | `spn-github-myproject-qa` |
| prod | `spn-github-myproject-prod` |

---

## Quick Reference

### Complete Setup Commands

```bash
# Variables
APP_NAME="spn-github-myproject"
GITHUB_ORG="myorg"
GITHUB_REPO="myproject"
SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 1. Create app registration
az ad app create --display-name "$APP_NAME"
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# 2. Create service principal
az ad sp create --id $APP_ID

# 3. Create federated credentials
for ENV in dev qa prod; do
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters '{
      "name": "github-'$ENV'",
      "issuer": "https://token.actions.githubusercontent.com",
      "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:'$ENV'",
      "audiences": ["api://AzureADTokenExchange"]
    }'
done

# 4. Assign role (use MSYS_NO_PATHCONV=1 in Git Bash)
MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# 5. Configure GitHub
gh variable set AZURE_CLIENT_ID --body "$APP_ID"
gh variable set AZURE_TENANT_ID --body "$(az account show --query tenantId -o tsv)"
gh variable set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
```

### Verification Checklist

- [ ] App registration exists: `az ad app show --id $APP_ID`
- [ ] Service principal exists: `az ad sp show --id $APP_ID`
- [ ] Federated credentials configured: `az ad app federated-credential list --id $APP_ID`
- [ ] Role assigned: `az role assignment list --assignee $APP_ID`
- [ ] GitHub variables set: `gh variable list`
- [ ] GitHub environments exist: `gh api repos/{owner}/{repo}/environments`

---

## See Also

- [AZURE_INTEGRATION.md](./AZURE_INTEGRATION.md) - Bicep modules and naming conventions
- [AUTHENTICATION.md](./AUTHENTICATION.md) - Power Platform service principal setup
- [Microsoft: Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation)
- [GitHub: OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)

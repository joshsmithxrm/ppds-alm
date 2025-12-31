# Azure Integration Bicep Modules

Reusable Bicep modules for Azure resources commonly used in Dataverse → Azure integrations.

---

## Overview

These modules provide a standardized way to deploy Azure infrastructure for Dataverse integration scenarios:

- **Service Endpoints** - Webhook and Service Bus triggers from Dataverse
- **Custom APIs** - Azure-hosted logic called from Dataverse
- **Virtual Tables** - External data surfaced in Dataverse

---

## Naming Conventions

These modules follow the [Microsoft Cloud Adoption Framework (CAF) naming conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

### Pattern

```
{resource-type}-{workload}-{environment}-[{region}]-{instance}
```

| Component | Required | Description |
|-----------|----------|-------------|
| `resource-type` | Yes | CAF abbreviation (e.g., `app`, `func`, `rg`) |
| `workload` | Yes | Application/project name (e.g., `ppdsdemo`) |
| `environment` | Yes | Environment name (`dev`, `qa`, `prod`) |
| `region` | No | Azure region - include for multi-region deployments |
| `instance` | No | Instance number (`001`, `002`) - include for multiple instances |

### Single-Region vs Multi-Region

**Be consistent** - either include region in all resource names or none.

#### Single-Region (Recommended for most projects)

Skip the region component when deploying to a single Azure region:

| Resource | Example |
|----------|---------|
| Resource Group | `rg-ppdsdemo-dev` |
| App Service | `app-ppdsdemo-dev-001` |
| Function App | `func-ppdsdemo-dev-001` |
| Service Bus | `sbns-ppdsdemo-dev-001` |

#### Multi-Region

Include region when the same workload is deployed to multiple Azure regions:

| Resource | East US | West US |
|----------|---------|---------|
| Resource Group | `rg-ppdsdemo-dev-eastus` | `rg-ppdsdemo-dev-westus` |
| App Service | `app-ppdsdemo-dev-eastus-001` | `app-ppdsdemo-dev-westus-001` |
| Function App | `func-ppdsdemo-dev-eastus-001` | `func-ppdsdemo-dev-westus-001` |
| Service Bus | `sbns-ppdsdemo-dev-eastus-001` | `sbns-ppdsdemo-dev-westus-001` |

### CAF Abbreviations

| Resource | Abbreviation |
|----------|--------------|
| Resource Group | `rg` |
| Log Analytics | `log` |
| Application Insights | `appi` |
| Storage Account | `st` |
| App Service Plan | `asp` |
| App Service | `app` |
| Function App | `func` |
| Service Bus Namespace | `sbns` |

### Global Uniqueness

Azure requires globally unique names for some resources (Storage Account, App Service, Function App, Service Bus). To avoid naming conflicts:

- Use an organization-specific `appNamePrefix` (e.g., `contoso-crm` not `myapp`)
- If you encounter name conflicts, use a more specific prefix

### Multi-Instance Deployments

Use the `instance` parameter to deploy multiple stacks in the same environment:

```bicep
// First deployment (default)
module integration1 'dataverse-integration.bicep' = {
  params: {
    appNamePrefix: 'ppdsdemo'
    environment: 'dev'
    instance: '001'  // default
  }
}

// Second deployment
module integration2 'dataverse-integration.bicep' = {
  params: {
    appNamePrefix: 'ppdsdemo'
    environment: 'dev'
    instance: '002'
  }
}
```

---

## Quick Start

### Using the GitHub Workflow (Recommended)

The easiest way to deploy is using the reusable GitHub Actions workflow:

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/azure-deploy.yml@v1
    with:
      environment: dev
      resource-group: rg-ppdsdemo-dev
      app-name-prefix: ppdsdemo
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      service-bus-queues: '[{"name": "account-updates"}]'
```

### Using the Composite Module Locally

For local development or custom deployments, clone the repository and reference the module:

```bicep
// After cloning ppds-alm to ./ppds-alm
module integration './ppds-alm/bicep/modules/dataverse-integration.bicep' = {
  name: 'dataverse-integration'
  params: {
    appNamePrefix: 'myapp'
    environment: 'dev'
    serviceBusQueues: [
      { name: 'account-updates' }
    ]
  }
}
```

---

## Available Modules

### Core Modules

| Module | Purpose |
|--------|---------|
| `log-analytics.bicep` | Log Analytics Workspace |
| `application-insights.bicep` | Application Insights |
| `storage-account.bicep` | Storage Account |
| `app-service-plan.bicep` | App Service Plan |
| `app-service.bicep` | App Service (Web API) |
| `function-app.bicep` | Azure Function App |
| `service-bus.bicep` | Service Bus namespace + queues |

### Composite Modules

| Module | Purpose |
|--------|---------|
| `dataverse-integration.bicep` | Complete infrastructure stack |

---

## Module Reference

### log-analytics.bicep

Creates a Log Analytics workspace for centralized logging.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `workspaceName` | string | Yes | - | Name of the workspace |
| `location` | string | No | resourceGroup().location | Azure region |
| `sku` | string | No | `PerGB2018` | Pricing tier |
| `retentionInDays` | int | No | `30` | Data retention (30-730) |
| `tags` | object | No | `{}` | Resource tags |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Resource ID |
| `name` | string | Workspace name |
| `workspaceId` | string | Customer ID for agents |

---

### application-insights.bicep

Creates Application Insights for application monitoring.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `appInsightsName` | string | Yes | - | Resource name |
| `location` | string | No | resourceGroup().location | Azure region |
| `logAnalyticsWorkspaceId` | string | Yes | - | Log Analytics workspace ID |
| `applicationType` | string | No | `web` | Application type |
| `tags` | object | No | `{}` | Resource tags |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Resource ID |
| `name` | string | Resource name |
| `connectionString` | string | Connection string |
| `instrumentationKey` | string | Instrumentation key (legacy) |

---

### storage-account.bicep

Creates a Storage Account for Function App storage.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `storageAccountName` | string | Yes | - | Name (3-24 chars, alphanumeric) |
| `location` | string | No | resourceGroup().location | Azure region |
| `sku` | string | No | `Standard_LRS` | Storage SKU |
| `kind` | string | No | `StorageV2` | Storage kind |
| `minimumTlsVersion` | string | No | `TLS1_2` | Minimum TLS version |
| `allowBlobPublicAccess` | bool | No | `false` | Allow public blob access |
| `tags` | object | No | `{}` | Resource tags |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Resource ID |
| `name` | string | Account name |
| `connectionString` | string | Primary connection string |
| `primaryBlobEndpoint` | string | Blob endpoint URL |

---

### app-service-plan.bicep

Creates an App Service Plan for hosting.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `planName` | string | Yes | - | Plan name |
| `location` | string | No | resourceGroup().location | Azure region |
| `sku` | string | No | `B1` | SKU (F1, B1, S1, P1v3, etc.) |
| `operatingSystem` | string | No | `Windows` | Windows or Linux |
| `capacity` | int | No | `1` | Number of workers |
| `tags` | object | No | `{}` | Resource tags |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Resource ID |
| `name` | string | Plan name |
| `skuName` | string | SKU name |

---

### app-service.bicep

Creates an App Service for Web API hosting.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `appName` | string | Yes | - | App name |
| `location` | string | No | resourceGroup().location | Azure region |
| `appServicePlanId` | string | Yes | - | App Service Plan ID |
| `netFrameworkVersion` | string | No | `v8.0` | .NET version |
| `appInsightsConnectionString` | string | No | `''` | App Insights connection |
| `enableManagedIdentity` | bool | No | `true` | Enable system identity |
| `appSettings` | array | No | `[]` | Additional app settings |
| `httpsOnly` | bool | No | `true` | HTTPS only |
| `tags` | object | No | `{}` | Resource tags |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Resource ID |
| `name` | string | App name |
| `defaultHostName` | string | Default hostname |
| `url` | string | Full URL |
| `principalId` | string | Managed identity principal ID |

---

### function-app.bicep

Creates an Azure Function App.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `functionAppName` | string | Yes | - | Function App name |
| `location` | string | No | resourceGroup().location | Azure region |
| `appServicePlanId` | string | Yes | - | App Service Plan ID |
| `storageAccountConnectionString` | string | Yes | - | Storage connection |
| `runtime` | string | No | `dotnet-isolated` | Runtime stack |
| `runtimeVersion` | string | No | `8.0` | Runtime version |
| `functionsExtensionVersion` | string | No | `~4` | Functions version |
| `appInsightsConnectionString` | string | No | `''` | App Insights connection |
| `enableManagedIdentity` | bool | No | `true` | Enable system identity |
| `appSettings` | array | No | `[]` | Additional app settings |
| `httpsOnly` | bool | No | `true` | HTTPS only |
| `tags` | object | No | `{}` | Resource tags |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Resource ID |
| `name` | string | Function App name |
| `defaultHostName` | string | Default hostname |
| `url` | string | Full URL |
| `principalId` | string | Managed identity principal ID |

---

### service-bus.bicep

Creates a Service Bus namespace with queues.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `namespaceName` | string | Yes | - | Namespace name |
| `location` | string | No | resourceGroup().location | Azure region |
| `sku` | string | No | `Basic` | SKU (Basic, Standard, Premium) |
| `queues` | array | No | `[]` | Queue configurations |
| `tags` | object | No | `{}` | Resource tags |

**Queue Configuration:**

```bicep
{
  name: 'queue-name'           // Required
  maxDeliveryCount: 10         // Optional, default: 10
  lockDuration: 'PT5M'         // Optional, default: PT5M
  defaultMessageTimeToLive: 'P14D'  // Optional, default: P14D
}
```

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `id` | string | Namespace resource ID |
| `name` | string | Namespace name |
| `connectionString` | string | Primary connection string |
| `endpoint` | string | Service Bus endpoint URL |

---

### dataverse-integration.bicep (Composite)

Deploys a complete Azure infrastructure stack.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `appNamePrefix` | string | Yes | - | Workload name (e.g., ppdsdemo) |
| `environment` | string | Yes | - | Environment (dev, qa, prod) |
| `location` | string | No | resourceGroup().location | Azure region |
| `instance` | string | No | `001` | Instance identifier for multi-deployment |
| `appServicePlanSku` | string | No | Based on env | App Service SKU |
| `serviceBusSku` | string | No | Based on env | Service Bus SKU |
| `serviceBusQueues` | array | No | `[]` | Queue configurations |
| `netFrameworkVersion` | string | No | `v8.0` | .NET version |
| `functionsRuntime` | string | No | `dotnet-isolated` | Functions runtime |
| `webApiAppSettings` | array | No | `[]` | Web API app settings |
| `functionAppSettings` | array | No | `[]` | Function app settings |
| `tags` | object | No | `{}` | Additional tags |

**Environment Defaults:**

| Setting | dev/qa | prod |
|---------|--------|------|
| App Service Plan SKU | B1 | P1v3 |
| Service Bus SKU | Basic | Standard |

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `webAppName` | string | Web App name |
| `webAppUrl` | string | Web App URL |
| `webAppPrincipalId` | string | Web App identity |
| `functionAppName` | string | Function App name |
| `functionAppUrl` | string | Function App URL |
| `functionAppPrincipalId` | string | Function App identity |
| `serviceBusNamespace` | string | Service Bus namespace |
| `serviceBusConnectionString` | string | Service Bus connection |
| `appInsightsName` | string | App Insights name |
| `appInsightsConnectionString` | string | App Insights connection |
| `logAnalyticsName` | string | Log Analytics name |
| `storageAccountName` | string | Storage account name |

---

## Workflow Reference

### azure-deploy.yml

**Inputs:**

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `environment` | string | Yes | - | dev, qa, or prod |
| `resource-group` | string | Yes | - | Azure resource group |
| `app-name-prefix` | string | Yes | - | Resource name prefix |
| `location` | string | No | `eastus` | Azure region |
| `bicep-file` | string | No | composite module | Custom Bicep file |
| `parameter-file` | string | No | - | Bicep parameters file |
| `service-bus-queues` | string | No | `[]` | JSON queue array |
| `azure-client-id` | string | Yes | - | Azure AD client ID (not a secret) |
| `azure-tenant-id` | string | Yes | - | Azure AD tenant ID (not a secret) |
| `azure-subscription-id` | string | Yes | - | Azure subscription ID (not a secret) |

> **Note:** `client-id`, `tenant-id`, and `subscription-id` are identifiers, not credentials.
> They are passed as inputs (use `${{ vars.* }}`), not secrets. OIDC authentication
> uses GitHub's token - no client secret is needed.

**Outputs:**

| Output | Description |
|--------|-------------|
| `web-app-name` | Deployed Web App name |
| `web-app-url` | Deployed Web App URL |
| `function-app-name` | Deployed Function App name |
| `function-app-url` | Deployed Function App URL |
| `service-bus-namespace` | Service Bus namespace |

---

## Authentication Setup

The workflow uses Azure federated credentials (OIDC). Set up:

1. Create an Azure AD App Registration
2. Add federated credential for GitHub Actions
3. Assign Contributor role to subscription/resource group
4. Store identifiers as GitHub **variables** (Settings → Secrets and variables → Actions → Variables):
   - `AZURE_CLIENT_ID` - App registration client ID
   - `AZURE_TENANT_ID` - Azure AD tenant ID
   - `AZURE_SUBSCRIPTION_ID` - Target subscription ID

> **Why variables, not secrets?** These are identifiers, not credentials. OIDC authentication
> works by exchanging GitHub's OIDC token with Azure AD - no client secret is involved.

See [AZURE_OIDC_SETUP.md](AZURE_OIDC_SETUP.md) for detailed setup instructions.

---

## Examples

### Basic Deployment

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/azure-deploy.yml@v1
    with:
      environment: dev
      resource-group: rg-ppdsdemo-dev
      app-name-prefix: ppdsdemo
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

### With Service Bus Queues

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/azure-deploy.yml@v1
    with:
      environment: prod
      resource-group: rg-ppdsdemo-prod
      app-name-prefix: ppdsdemo
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      service-bus-queues: |
        [
          {"name": "account-updates", "maxDeliveryCount": 10},
          {"name": "notifications", "maxDeliveryCount": 5}
        ]
```

### Using Individual Modules

```bicep
// Deploy just the modules you need
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'log-analytics'
  params: {
    workspaceName: 'myapp-log-dev'
  }
}

module serviceBus 'modules/service-bus.bicep' = {
  name: 'service-bus'
  params: {
    namespaceName: 'myapp-sb-dev'
    queues: [
      { name: 'account-updates' }
    ]
  }
}
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Azure Resource Group                                           │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │ Log Analytics   │◄───│ Application Insights                │ │
│  └─────────────────┘    └─────────────────────────────────────┘ │
│                                      │                          │
│                         ┌────────────┴────────────┐             │
│                         ▼                         ▼             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Storage Account │  │ App Service     │  │ Function App    │  │
│  │ (Functions)     │  │ (Web API)       │  │ (Triggers)      │  │
│  └─────────────────┘  └────────┬────────┘  └────────┬────────┘  │
│                                │                    │           │
│                                └────────┬───────────┘           │
│                                         │                       │
│                         ┌───────────────┴───────────────┐       │
│                         ▼                               ▼       │
│                    ┌─────────────────┐          ┌─────────────┐ │
│                    │ App Service Plan│          │ Service Bus │ │
│                    │ (Shared)        │          │ (Queues)    │ │
│                    └─────────────────┘          └─────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Related Documentation

- [GITHUB_QUICKSTART.md](GITHUB_QUICKSTART.md) - GitHub Actions setup
- [AZURE_OIDC_SETUP.md](AZURE_OIDC_SETUP.md) - Azure OIDC credential setup
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

# Azure and Dataverse Coordination

This guide covers patterns for coordinating Azure infrastructure and Dataverse solution deployments.

---

## Overview

Many Power Platform solutions integrate with Azure services:

- **Service Endpoints** - Webhooks calling Azure Functions
- **Custom APIs** - Azure-hosted logic called from Dataverse
- **Virtual Tables** - External data surfaced in Dataverse
- **Event Processing** - Service Bus triggers from Dataverse

This creates deployment coordination challenges: which should deploy first?

---

## The Challenge

### Deployment Dependencies

```
Dataverse Solution                    Azure Infrastructure
┌────────────────────┐                ┌──────────────────────┐
│ Plugin Steps       │───webhook───►  │ Function App         │
│ Service Endpoints  │                │ (URL needed at deploy)│
│ Environment Vars   │───value────►   │ App Settings         │
│ Connection Refs    │                │ Managed Identity     │
└────────────────────┘                └──────────────────────┘
         │                                      │
         └──────── Which deploys first? ────────┘
```

### Common Problems

| Problem | Cause |
|---------|-------|
| Webhook fails | Azure Function not deployed yet |
| Missing env vars | Azure URLs not known at deploy time |
| Connection errors | Managed identity not configured |

---

## Recommended Pattern: Infrastructure-First

Deploy Azure infrastructure **before** Dataverse solutions.

### Why Infrastructure-First?

1. **Azure URLs are stable** - Function App URLs don't change after creation
2. **Outputs feed into Dataverse** - Environment variables can reference Azure endpoints
3. **Infrastructure is environment-specific** - Same solution, different Azure resources per env

### Implementation

```yaml
name: Full Deployment

on:
  push:
    branches: [main]

jobs:
  # Step 1: Deploy Azure infrastructure
  deploy-azure:
    uses: joshsmithxrm/ppds-alm/.github/workflows/azure-deploy.yml@v1
    with:
      environment: prod
      resource-group: rg-myapp-prod
      app-name-prefix: myapp
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

  # Step 2: Generate deployment settings with Azure URLs
  prepare-settings:
    needs: deploy-azure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate deployment settings
        run: |
          cat > config/MySolution.prod.deploymentsettings.json << EOF
          {
            "EnvironmentVariables": [
              {
                "SchemaName": "new_AzureFunctionUrl",
                "Value": "${{ needs.deploy-azure.outputs.function-app-url }}"
              },
              {
                "SchemaName": "new_WebApiUrl",
                "Value": "${{ needs.deploy-azure.outputs.web-app-url }}"
              }
            ]
          }
          EOF

      - uses: actions/upload-artifact@v4
        with:
          name: deployment-settings
          path: config/

  # Step 3: Deploy Dataverse solution with settings
  deploy-dataverse:
    needs: [deploy-azure, prepare-settings]
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      package-type: Managed
      settings-file: config/MySolution.prod.deploymentsettings.json
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

---

## Deployment Settings Patterns

### Static Settings (Checked In)

For values that don't change per deployment:

```
config/
├── MySolution.dev.deploymentsettings.json
├── MySolution.qa.deploymentsettings.json
└── MySolution.prod.deploymentsettings.json
```

### Dynamic Settings (Generated)

For Azure-dependent values, generate at deploy time:

```yaml
- name: Generate settings
  run: |
    # Merge static settings with dynamic Azure URLs
    jq --arg url "${{ needs.azure.outputs.function-url }}" \
      '.EnvironmentVariables += [{"SchemaName": "new_Url", "Value": $url}]' \
      config/MySolution.static.json > config/MySolution.prod.deploymentsettings.json
```

### Hybrid Approach

Use static settings with placeholders, replace at deploy time:

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "new_AzureFunctionUrl",
      "Value": "{{AZURE_FUNCTION_URL}}"
    }
  ]
}
```

```yaml
- name: Replace placeholders
  run: |
    sed -i "s|{{AZURE_FUNCTION_URL}}|${{ needs.azure.outputs.function-url }}|g" \
      config/MySolution.prod.deploymentsettings.json
```

---

## Environment Strategy

### Separate Azure Resources per Environment

Each Dataverse environment should have its own Azure resources:

| Dataverse Env | Azure Resource Group | Naming |
|---------------|---------------------|--------|
| dev.crm.dynamics.com | rg-myapp-dev | func-myapp-dev-001 |
| qa.crm.dynamics.com | rg-myapp-qa | func-myapp-qa-001 |
| prod.crm.dynamics.com | rg-myapp-prod | func-myapp-prod-001 |

### Single Pipeline, Multiple Environments

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        environment: [dev, qa, prod]
    environment: ${{ matrix.environment }}
    steps:
      - uses: joshsmithxrm/ppds-alm/.github/workflows/azure-deploy.yml@v1
        with:
          environment: ${{ matrix.environment }}
          resource-group: rg-myapp-${{ matrix.environment }}
          # ...
```

---

## First-Time Setup

### Challenge: Chicken-and-Egg

When setting up a new environment:

1. Solution needs Azure URLs in environment variables
2. Azure resources don't exist yet
3. Solution import fails

### Solution: Two-Phase Deployment

**Phase 1: Infrastructure Only**

```yaml
# First run: Just Azure
jobs:
  azure:
    uses: .../azure-deploy.yml@v1
    # Creates resources, outputs URLs
```

**Phase 2: Add Dataverse**

```yaml
# Subsequent runs: Azure + Dataverse
jobs:
  azure:
    uses: .../azure-deploy.yml@v1

  dataverse:
    needs: azure
    uses: .../solution-deploy.yml@v1
    # Now has Azure URLs for settings
```

### Alternative: Pre-created Azure Resources

Create Azure resources via Bicep/Portal before solution work begins. This is simpler for stable environments.

---

## Rollback Considerations

### Azure Rollback

Azure resources can be rolled back by:
- Redeploying previous Bicep with same parameters
- Using Azure deployment history

### Dataverse Rollback

Dataverse uses **roll-forward** strategy:
- No true rollback mechanism
- Fix issues in a new version
- Redeploy the corrected solution

### Coordinated Rollback

If both Azure and Dataverse need rollback:

1. Identify the compatible versions
2. Redeploy Azure to that version
3. Export and redeploy Dataverse solution from that point

---

## Monitoring Integration

### Azure Application Insights → Dataverse

```bicep
// In azure-deploy
output appInsightsConnectionString string = appInsights.properties.ConnectionString
```

```yaml
# Pass to solution settings
- name: Generate settings
  run: |
    jq --arg conn "${{ needs.azure.outputs.app-insights-connection }}" \
      '.EnvironmentVariables += [{"SchemaName": "new_AppInsightsConnection", "Value": $conn}]' \
      ...
```

### Plugin Logging to Azure

Configure plugins to log to Application Insights using the connection string environment variable.

---

## Common Issues

### Issue: Azure URLs Not Available

**Symptom:** Solution import fails because environment variables reference non-existent Azure resources.

**Solution:** Ensure Azure deployment completes and outputs are captured before solution deployment starts.

### Issue: Settings File Not Updated

**Symptom:** Deployment uses stale Azure URLs.

**Solution:** Generate settings dynamically from Azure outputs, don't rely on committed files.

### Issue: Managed Identity Not Ready

**Symptom:** Azure services can't authenticate to Dataverse.

**Solution:** Configure Dataverse application user for the Azure managed identity after infrastructure deployment.

---

## See Also

- [AZURE_INTEGRATION.md](./AZURE_INTEGRATION.md) - Bicep modules reference
- [AZURE_OIDC_SETUP.md](./AZURE_OIDC_SETUP.md) - Azure authentication setup
- [WORKFLOWS_REFERENCE.md](./WORKFLOWS_REFERENCE.md) - All workflows
- [FEATURES.md](./FEATURES.md) - Deployment settings auto-detection

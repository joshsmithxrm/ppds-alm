# Azure DevOps Quickstart

This guide shows you how to use PPDS ALM templates in your Azure DevOps pipelines.

## Prerequisites

1. An Azure DevOps project with your Dataverse solution
2. An Azure AD app registration for authentication
3. Service connections configured for Dataverse environments
4. Access to the PPDS ALM repository

## Available Templates

| Template | Description |
|----------|-------------|
| `plugin-deploy.yml` | Deploy plugins to Dataverse |
| `plugin-extract.yml` | Extract plugin registrations from assembly |
| `solution-export.yml` | Export solution from Dataverse |
| `solution-import.yml` | Import solution to Dataverse |
| `full-alm.yml` | Complete ALM pipeline |

## Quick Start

### 1. Create Service Connections

1. Go to **Project Settings > Service connections**
2. Create a new **Power Platform** service connection
3. Or create an **Azure Resource Manager** service connection with service principal

### 2. Add Repository Resource

In your `azure-pipelines.yml`, add the PPDS ALM repository:

```yaml
resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0
      endpoint: 'GitHub Connection'  # Your GitHub service connection
```

### 3. Use Templates

Reference templates from the repository:

```yaml
trigger:
  - main

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0
      endpoint: 'GitHub Connection'

stages:
  - template: azure-devops/templates/plugin-deploy.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg.crm.dynamics.com'
      registrationFile: './src/Plugins/registrations.json'
      detectDrift: true
      serviceConnection: 'Dataverse Production'
```

## Setting Up Service Connections

### Option 1: Power Platform Service Connection

1. In Azure DevOps, go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Enter your environment URL and app registration details
5. Give it a descriptive name (e.g., "Dataverse Dev", "Dataverse Prod")

### Option 2: Azure Service Connection

1. Create a new **Azure Resource Manager** connection
2. Select **Service principal (manual)**
3. Enter your app registration details
4. The templates will extract credentials from this connection

## Example Pipelines

### Basic Plugin Deployment

```yaml
trigger:
  - main

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0
      endpoint: 'GitHub'

stages:
  - template: azure-devops/templates/plugin-deploy.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg.crm.dynamics.com'
      registrationFile: './registrations.json'
      serviceConnection: 'Dataverse Prod'
```

### Extract Plugin Registrations

```yaml
trigger: none  # Manual trigger only

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0
      endpoint: 'GitHub'

stages:
  - template: azure-devops/templates/plugin-extract.yml@ppds-alm
    parameters:
      assemblyPath: './bin/Release/net462/MyPlugins.dll'
      outputPath: './registrations.json'
```

### Multi-Environment Deployment

```yaml
trigger:
  branches:
    include:
      - main
      - release/*

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0
      endpoint: 'GitHub'

variables:
  solutionName: 'MySolution'

stages:
  # Export from Dev
  - template: azure-devops/templates/solution-export.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg-dev.crm.dynamics.com'
      solutionName: $(solutionName)
      managed: true
      serviceConnection: 'Dataverse Dev'

  # Import to Test
  - template: azure-devops/templates/solution-import.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg-test.crm.dynamics.com'
      solutionFile: './solutions/$(solutionName)_managed.zip'
      serviceConnection: 'Dataverse Test'

  # Deploy plugins to Test
  - template: azure-devops/templates/plugin-deploy.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg-test.crm.dynamics.com'
      registrationFile: './registrations.json'
      serviceConnection: 'Dataverse Test'
```

### Full ALM Pipeline

```yaml
trigger:
  - main

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0
      endpoint: 'GitHub'

stages:
  - template: azure-devops/templates/full-alm.yml@ppds-alm
    parameters:
      sourceEnvironmentUrl: 'https://myorg-dev.crm.dynamics.com'
      targetEnvironmentUrl: 'https://myorg.crm.dynamics.com'
      solutionName: 'MySolution'
      deployManaged: true
      deployPlugins: true
      pluginRegistrationFile: './registrations.json'
      sourceServiceConnection: 'Dataverse Dev'
      targetServiceConnection: 'Dataverse Prod'
```

## Template Parameters Reference

### plugin-deploy.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `environmentUrl` | Yes | - | Dataverse environment URL |
| `registrationFile` | No | `./registrations.json` | Path to registrations JSON |
| `detectDrift` | No | `true` | Run drift detection |
| `serviceConnection` | Yes | - | Azure service connection name |
| `workingDirectory` | No | `$(System.DefaultWorkingDirectory)` | Working directory |

### plugin-extract.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `assemblyPath` | Yes | - | Path to plugin DLL |
| `outputPath` | No | `./registrations.json` | Output file path |
| `workingDirectory` | No | `$(System.DefaultWorkingDirectory)` | Working directory |
| `publishArtifact` | No | `true` | Publish as pipeline artifact |
| `artifactName` | No | `plugin-registrations` | Artifact name |

### solution-export.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `environmentUrl` | Yes | - | Source environment URL |
| `solutionName` | Yes | - | Solution unique name |
| `outputPath` | No | `./solutions` | Output directory |
| `managed` | No | `false` | Export as managed |
| `serviceConnection` | Yes | - | Azure service connection |
| `workingDirectory` | No | `$(System.DefaultWorkingDirectory)` | Working directory |

### solution-import.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `environmentUrl` | Yes | - | Target environment URL |
| `solutionFile` | Yes | - | Path to solution zip |
| `publishChanges` | No | `true` | Publish after import |
| `activatePlugins` | No | `true` | Activate plugin steps |
| `overwriteUnmanaged` | No | `false` | Overwrite customizations |
| `serviceConnection` | Yes | - | Azure service connection |
| `workingDirectory` | No | `$(System.DefaultWorkingDirectory)` | Working directory |

## Using Environments for Approvals

Create environments in Azure DevOps for approval gates:

1. Go to **Pipelines > Environments**
2. Create environments (e.g., "Test", "Production")
3. Add approval checks to each environment
4. Use deployment jobs in your pipelines

See the [advanced-pipeline.yml](../azure-devops/examples/advanced-pipeline.yml) example.

## Troubleshooting

### Service Connection Issues

- Verify the service connection has correct credentials
- Check the app registration has required permissions
- Test the connection in the service connection settings

### Template Not Found

- Ensure the repository resource is correctly configured
- Verify the endpoint (GitHub service connection) exists
- Check the ref points to a valid tag or branch

### Power Platform Build Tools

- The templates use Microsoft's Power Platform Build Tools
- Ensure your Azure DevOps organization has access to the extension
- Install from the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerPlatform-BuildTools)

See [Troubleshooting](./troubleshooting.md) for more help.

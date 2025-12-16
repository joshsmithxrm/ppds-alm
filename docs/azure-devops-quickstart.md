# Azure DevOps Quickstart

This guide shows you how to use PPDS ALM templates in your Azure DevOps pipelines.

> **Note:** Azure DevOps templates are planned for Phase 3 of the v2 migration. Currently, the templates follow v1 patterns. This guide describes the intended v2 functionality.

## Prerequisites

1. An Azure DevOps project with your Power Platform solution
2. An Azure AD app registration for authentication
3. Service connections configured (see [Authentication](./authentication.md))

## Quick Setup

### 1. Configure Service Connection

1. Go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Fill in:
   - **Server URL**: Your environment URL (e.g., `https://myorg.crm.dynamics.com`)
   - **Tenant ID**: Your Azure AD tenant ID
   - **Application ID**: Your app's Client ID
   - **Client secret**: Your app's Client Secret
5. Name it descriptively (e.g., "Dataverse QA")
6. Click **Save**

### 2. Reference PPDS ALM Templates

Add the repository resource to your pipeline:

```yaml
resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v2.0.0
      endpoint: 'GitHub Connection'  # Your GitHub service connection name
```

### 3. Create Your First Pipeline

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v2.0.0
      endpoint: 'GitHub Connection'

stages:
  - template: azure-devops/templates/solution-deploy.yml@ppds-alm
    parameters:
      solutionName: MySolution
      solutionFolder: solutions/MySolution/src
      serviceConnection: 'Dataverse Prod'
      packageType: Managed
```

## Available Templates

### Solution Templates

| Template | Purpose |
|----------|---------|
| `solution-export.yml` | Export solution from environment |
| `solution-import.yml` | Import solution to environment |
| `solution-build.yml` | Build .NET code and pack solution |
| `solution-validate.yml` | PR validation with Solution Checker |
| `solution-deploy.yml` | Full deployment pipeline |

### Plugin Templates

| Template | Purpose |
|----------|---------|
| `plugin-deploy.yml` | Deploy plugins using PPDS.Tools |
| `plugin-extract.yml` | Extract plugin registrations |

### Complete Pipeline

| Template | Purpose |
|----------|---------|
| `full-alm.yml` | Complete ALM pipeline |

## Example Pipelines

### Basic Deployment Pipeline

```yaml
trigger:
  branches:
    include:
      - develop

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v2.0.0
      endpoint: 'GitHub'

stages:
  - template: azure-devops/templates/solution-deploy.yml@ppds-alm
    parameters:
      solutionName: MySolution
      solutionFolder: solutions/MySolution/src
      serviceConnection: 'Dataverse QA'
      buildPlugins: true
      packageType: Managed
```

### Multi-Environment Pipeline

```yaml
trigger:
  branches:
    include:
      - main

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v2.0.0
      endpoint: 'GitHub'

stages:
  # Build stage
  - stage: Build
    jobs:
      - template: azure-devops/templates/solution-build.yml@ppds-alm
        parameters:
          solutionName: MySolution
          solutionFolder: solutions/MySolution/src
          buildPlugins: true
          runTests: true

  # Deploy to QA
  - stage: DeployQA
    dependsOn: Build
    jobs:
      - deployment: DeployToQA
        environment: QA
        strategy:
          runOnce:
            deploy:
              steps:
                - template: azure-devops/templates/solution-import.yml@ppds-alm
                  parameters:
                    solutionName: MySolution
                    serviceConnection: 'Dataverse QA'
                    packageType: Managed

  # Deploy to Production (with approval)
  - stage: DeployProd
    dependsOn: DeployQA
    jobs:
      - deployment: DeployToProd
        environment: Production  # Configure approval in Azure DevOps
        strategy:
          runOnce:
            deploy:
              steps:
                - template: azure-devops/templates/solution-import.yml@ppds-alm
                  parameters:
                    solutionName: MySolution
                    serviceConnection: 'Dataverse Prod'
                    packageType: Managed
```

### PR Validation Pipeline

```yaml
trigger: none

pr:
  branches:
    include:
      - develop
      - main

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v2.0.0
      endpoint: 'GitHub'

stages:
  - template: azure-devops/templates/solution-validate.yml@ppds-alm
    parameters:
      solutionName: MySolution
      solutionFolder: solutions/MySolution/src
      buildCode: true
      runTests: true
      runSolutionChecker: true
      checkerFailLevel: High
      serviceConnection: 'Dataverse Dev'
```

### Nightly Export Pipeline

```yaml
trigger: none

schedules:
  - cron: '0 2 * * *'  # 2 AM daily
    displayName: Nightly Export
    branches:
      include:
        - develop

resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v2.0.0
      endpoint: 'GitHub'

stages:
  - template: azure-devops/templates/solution-export.yml@ppds-alm
    parameters:
      solutionName: MySolution
      solutionFolder: solutions/MySolution/src
      serviceConnection: 'Dataverse Dev'
      filterNoise: true
      commitChanges: true
```

## Template Parameters Reference

### solution-deploy.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `solutionName` | Yes | - | Solution unique name |
| `solutionFolder` | Yes | - | Path to unpacked solution |
| `serviceConnection` | Yes | - | Azure DevOps service connection name |
| `buildPlugins` | No | `false` | Build .NET solution |
| `dotnetSolutionPath` | No | Auto-detect | Path to .sln file |
| `packageType` | No | `Managed` | Managed or Unmanaged |
| `skipIfSameVersion` | No | `true` | Skip if target has same version |
| `maxRetries` | No | `3` | Retry attempts |
| `settingsFile` | No | Auto-detect | Deployment settings path |

### solution-validate.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `solutionName` | Yes | - | Solution unique name |
| `solutionFolder` | Yes | - | Path to unpacked solution |
| `serviceConnection` | No | - | Required for Solution Checker |
| `buildCode` | No | `true` | Build .NET solution |
| `runTests` | No | `true` | Run unit tests |
| `runSolutionChecker` | No | `false` | Run Solution Checker |
| `checkerFailLevel` | No | `High` | Fail threshold |

### solution-build.yml

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `solutionName` | Yes | - | Solution unique name |
| `solutionFolder` | Yes | - | Path to unpacked solution |
| `buildPlugins` | No | `false` | Build .NET solution |
| `dotnetSolutionPath` | No | Auto-detect | Path to .sln file |
| `runTests` | No | `false` | Run unit tests |
| `packageType` | No | `Both` | Managed, Unmanaged, or Both |

## Service Connection Setup

### Option 1: Power Platform Service Connection

Recommended for solution operations:

1. Project Settings > Service connections
2. New service connection > Power Platform
3. Enter credentials
4. Use in templates: `serviceConnection: 'Connection Name'`

### Option 2: Generic Service Connection

For custom scenarios:

1. Project Settings > Service connections
2. New service connection > Generic
3. Enter environment URL and credentials
4. Reference in custom scripts

## Variable Groups

Create variable groups for shared configuration:

```yaml
variables:
  - group: PowerPlatform-Dev
  - group: PowerPlatform-QA
  - group: PowerPlatform-Prod
```

**Variable Group Contents:**
- `EnvironmentUrl`: Power Platform environment URL
- `TenantId`: Azure AD tenant ID
- `ClientId`: Service principal client ID
- `ClientSecret`: Service principal secret (mark as secret)

## Troubleshooting

### "Repository 'ppds-alm' not found"

**Solution:**
1. Verify the GitHub service connection exists
2. Check the service connection has access to the repository
3. Ensure the repository resource is defined correctly:
```yaml
resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      endpoint: 'Your GitHub Service Connection'
```

### "Template not found"

**Solution:**
1. Verify the template path matches exactly
2. Ensure `@ppds-alm` suffix is included
3. Check the ref points to a valid tag/branch

### "Service connection not found"

**Solution:**
1. Verify the exact name of your service connection
2. Check spelling and case sensitivity
3. Ensure the pipeline has access to the service connection

### Authentication Issues

See [Authentication Guide](./authentication.md) for detailed setup instructions.

## Comparison: GitHub Actions vs Azure DevOps

| Feature | GitHub Actions | Azure DevOps |
|---------|----------------|--------------|
| Composite actions | ✅ Full support | ⚠️ Limited (use step templates) |
| Reusable workflows | ✅ `workflow_call` | ✅ Template references |
| Environments | ✅ Environments | ✅ Environments |
| Approval gates | ✅ Environment protection | ✅ Checks and approvals |
| Secrets | ✅ Repository/Environment secrets | ✅ Variable groups |

## See Also

- [GitHub Actions Quickstart](./github-quickstart.md) - GitHub-specific guide
- [Authentication Guide](./authentication.md) - Service principal setup
- [Troubleshooting](./troubleshooting.md) - Common issues
- [Migration Guide](./migration-v2.md) - Upgrading from v1

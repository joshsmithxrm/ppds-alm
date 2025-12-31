# Workflows Reference

This document provides a complete reference for all reusable workflows in ppds-alm.

---

## Overview

ppds-alm provides reusable workflows that orchestrate common Power Platform ALM scenarios. These workflows call the composite actions internally and handle multi-step processes.

### When to Use Workflows vs Actions

| Use Case | Recommendation |
|----------|----------------|
| Standard ALM scenarios | Use **workflows** for simplicity |
| Custom pipelines | Use **actions** for flexibility |
| Quick setup | Use **workflows** - minimal configuration |
| Complex orchestration | Use **actions** - compose your own flow |

See [CONSUMPTION_GUIDE.md](./CONSUMPTION_GUIDE.md) for detailed guidance.

---

## Solution Workflows

### solution-export.yml

Exports a solution from a Dataverse environment and unpacks it to source control format.

**Usage:**

```yaml
jobs:
  export:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-export.yml@v1
    with:
      solution-name: MySolution
      output-folder: solutions/MySolution/src
      filter-noise: true
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name to export |
| `output-folder` | Yes | - | Folder for unpacked solution |
| `temp-folder` | No | `./exports` | Temporary folder for zip files |
| `filter-noise` | No | `true` | Filter volatile changes (version stamps, etc.) |
| `set-version` | No | - | Version to stamp before export |
| `debug` | No | `false` | Enable debug logging |

**Outputs:**

| Output | Description |
|--------|-------------|
| `solution-folder` | Path to unpacked solution folder |
| `has-real-changes` | Whether non-noise changes were detected |
| `change-summary` | Summary of changes detected |
| `version` | Version of exported solution |

---

### solution-import.yml

Imports a solution into a Dataverse environment with version checking and retry logic.

**Usage:**

```yaml
jobs:
  import:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-import.yml@v1
    with:
      solution-path: ./exports/MySolution_managed.zip
      solution-name: MySolution
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-path` | Yes | - | Path to solution zip file |
| `solution-name` | No | - | Solution name (for version check) |
| `skip-if-same-version` | No | `true` | Skip if target has same/newer version |
| `max-retries` | No | `3` | Retry attempts for transient failures |
| `settings-file` | No | - | Deployment settings JSON file |
| `publish-changes` | No | `true` | Publish customizations after import |

**Outputs:**

| Output | Description |
|--------|-------------|
| `deployed` | Whether deployment completed |
| `skipped` | Whether deployment was skipped (version match) |
| `import-version` | Version that was imported |
| `target-version` | Version in target before import |

---

### solution-build.yml

Builds a solution including optional .NET code compilation and packs to zip.

**Usage:**

```yaml
jobs:
  build:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-build.yml@v1
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-plugins: true
      dotnet-solution-path: MySolution.sln
      run-tests: true
      package-type: Both
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path to unpacked solution |
| `output-folder` | No | `./exports` | Output folder for packed files |
| `package-type` | No | `Both` | Managed, Unmanaged, or Both |
| `build-plugins` | No | `false` | Build .NET solution |
| `dotnet-solution-path` | No | - | Path to .sln file |
| `run-tests` | No | `false` | Run unit tests |
| `configuration` | No | `Release` | Build configuration |

**Outputs:**

| Output | Description |
|--------|-------------|
| `solution-path` | Path to primary packed solution |
| `build-succeeded` | Whether .NET build succeeded |
| `test-succeeded` | Whether tests passed |
| `version` | Solution version |

---

### solution-validate.yml

Validates a solution for PR checks - builds, packs, and optionally runs Solution Checker.

**Usage:**

```yaml
jobs:
  validate:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-validate.yml@v1
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-code: true
      run-tests: true
      run-solution-checker: true
      checker-fail-level: High
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path to unpacked solution |
| `build-code` | No | `true` | Build .NET solution |
| `run-tests` | No | `true` | Run unit tests |
| `run-solution-checker` | No | `false` | Run Solution Checker |
| `checker-fail-level` | No | `High` | Fail threshold (Critical/High/Medium/Low/Informational) |
| `checker-geography` | No | `unitedstates` | Checker geography |

**Outputs:**

| Output | Description |
|--------|-------------|
| `build-passed` | Whether build passed |
| `pack-passed` | Whether packing passed |
| `check-passed` | Whether Solution Checker passed |

---

### solution-deploy.yml

Complete deployment workflow - builds plugins, packs solution, and imports to environment.

**Usage:**

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-plugins: true
      package-type: Managed
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path to unpacked solution |
| `build-plugins` | No | `false` | Build .NET solution |
| `dotnet-solution-path` | No | - | Path to .sln file |
| `package-type` | No | `Managed` | Managed or Unmanaged |
| `skip-if-same-version` | No | `true` | Skip if version matches |
| `max-retries` | No | `3` | Retry attempts |
| `settings-file` | No | Auto-detect | Deployment settings file |

**Outputs:**

| Output | Description |
|--------|-------------|
| `deployed` | Whether deployment completed |
| `skipped` | Whether skipped (version match) |
| `version` | Solution version deployed |
| `build-succeeded` | Whether build succeeded |

---

### solution-promote.yml

Promotes a solution from source to target environment (environment-to-environment).

Use this for promoting between environments (dev → qa → prod). For deploying from git to an environment, use `solution-deploy.yml` instead.

**Usage:**

```yaml
jobs:
  promote:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-promote.yml@v1
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      deploy-managed: true
      build-plugins: true
    secrets:
      source-environment-url: ${{ vars.SOURCE_ENVIRONMENT_URL }}
      source-tenant-id: ${{ vars.SOURCE_TENANT_ID }}
      source-client-id: ${{ vars.SOURCE_CLIENT_ID }}
      source-client-secret: ${{ secrets.SOURCE_CLIENT_SECRET }}
      target-environment-url: ${{ vars.TARGET_ENVIRONMENT_URL }}
      target-tenant-id: ${{ vars.TARGET_TENANT_ID }}
      target-client-id: ${{ vars.TARGET_CLIENT_ID }}
      target-client-secret: ${{ secrets.TARGET_CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path for unpacked solution |
| `deploy-managed` | No | `true` | Deploy as managed |
| `build-plugins` | No | `false` | Build .NET solution |
| `dotnet-solution-path` | No | - | Path to .sln file |
| `skip-if-same-version` | No | `true` | Skip if version matches |

**Secrets (all required):**

| Secret | Description |
|--------|-------------|
| `source-environment-url` | Source environment URL |
| `source-tenant-id` | Source tenant ID |
| `source-client-id` | Source client ID |
| `source-client-secret` | Source client secret |
| `target-environment-url` | Target environment URL |
| `target-tenant-id` | Target tenant ID |
| `target-client-id` | Target client ID |
| `target-client-secret` | Target client secret |

**Outputs:**

| Output | Description |
|--------|-------------|
| `exported` | Whether export succeeded |
| `deployed` | Whether deployment succeeded |
| `skipped` | Whether skipped (version match) |
| `version` | Solution version |

---

## Plugin Workflows

### plugin-extract.yml

Extracts plugin registrations from a compiled assembly using PPDS CLI.

**Usage:**

```yaml
jobs:
  extract:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-extract.yml@v1
    with:
      assembly-path: ./src/Plugins/bin/Release/net462/MyPlugins.dll
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `assembly-path` | Yes | - | Path to compiled plugin assembly |
| `output-path` | No | `./registrations.json` | Output registrations file |
| `ppds-cli-version` | No | Latest | PPDS CLI version to install |

**Outputs:**

| Output | Description |
|--------|-------------|
| `registration-file` | Path to generated registrations file |

---

### plugin-deploy.yml

Deploys plugins to a Dataverse environment using PPDS CLI with drift detection.

**Usage:**

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1
    with:
      registration-file: ./registrations.json
    secrets:
      environment-url: ${{ secrets.ENVIRONMENT_URL }}
      tenant-id: ${{ vars.TENANT_ID }}
      client-id: ${{ vars.CLIENT_ID }}
      client-secret: ${{ secrets.CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registration-file` | No | `./registrations.json` | Plugin registrations file |
| `detect-drift` | No | `true` | Run drift detection first |
| `ppds-cli-version` | No | Latest | PPDS CLI version to install |

**Outputs:**

| Output | Description |
|--------|-------------|
| `deployed` | Whether plugins were deployed |
| `drift-detected` | Whether drift was detected |

---

## Azure Workflows

### azure-deploy.yml

Deploys Azure infrastructure for Dataverse integration using Bicep modules.

**Usage:**

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

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Environment name (dev/qa/prod) |
| `resource-group` | Yes | - | Azure resource group |
| `app-name-prefix` | Yes | - | Application name prefix |
| `location` | No | `eastus` | Azure region |
| `bicep-file` | No | Composite module | Custom Bicep file |
| `parameter-file` | No | - | Bicep parameters file |
| `service-bus-queues` | No | `[]` | JSON array of queues |
| `azure-client-id` | Yes | - | Azure AD client ID |
| `azure-tenant-id` | Yes | - | Azure AD tenant ID |
| `azure-subscription-id` | Yes | - | Azure subscription ID |

> Note: Azure identifiers are passed as inputs (not secrets) because they are not credentials. OIDC authentication uses GitHub's token.

**Outputs:**

| Output | Description |
|--------|-------------|
| `web-app-name` | Deployed Web App name |
| `web-app-url` | Deployed Web App URL |
| `function-app-name` | Deployed Function App name |
| `function-app-url` | Deployed Function App URL |
| `service-bus-namespace` | Service Bus namespace |

See [AZURE_INTEGRATION.md](./AZURE_INTEGRATION.md) for Bicep modules and [AZURE_OIDC_SETUP.md](./AZURE_OIDC_SETUP.md) for authentication setup.

---

## Version Tags

Always use version tags for stability:

```yaml
# Recommended: major version tag (gets non-breaking updates)
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1

# Locked to specific version (maximum stability)
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1.0.0

# Not recommended for production
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@main
```

---

## See Also

- [ACTIONS_REFERENCE.md](./ACTIONS_REFERENCE.md) - Composite actions reference
- [CONSUMPTION_GUIDE.md](./CONSUMPTION_GUIDE.md) - When to use actions vs workflows
- [GITHUB_QUICKSTART.md](./GITHUB_QUICKSTART.md) - Getting started guide
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues

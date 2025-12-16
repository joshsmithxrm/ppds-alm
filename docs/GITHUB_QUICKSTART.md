# GitHub Actions Quickstart

This guide shows you how to use PPDS ALM v2 reusable workflows and composite actions in your GitHub Actions pipelines.

## Prerequisites

1. A GitHub repository with your Power Platform solution
2. An Azure AD app registration for authentication
3. GitHub repository secrets configured (see [Authentication](./authentication.md))

## Quick Setup

### 1. Configure GitHub Environment

1. Go to **Settings > Environments > New environment**
2. Create environments for each target (e.g., `Dev`, `QA`, `Prod`)
3. Add variables and secrets to each environment:

**Variables:**
| Variable | Example |
|----------|---------|
| `POWERPLATFORM_ENVIRONMENT_URL` | `https://myorg-qa.crm.dynamics.com/` |
| `POWERPLATFORM_TENANT_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `POWERPLATFORM_CLIENT_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

**Secrets:**
| Secret | Description |
|--------|-------------|
| `POWERPLATFORM_CLIENT_SECRET` | Service principal client secret |

### 2. Create Your First Workflow

Create `.github/workflows/deploy-qa.yml`:

```yaml
name: Deploy to QA

on:
  push:
    branches: [develop]
  workflow_dispatch:

jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
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

## Available Workflows

### Solution Workflows

| Workflow | Purpose | When to Use |
|----------|---------|-------------|
| `solution-export.yml` | Export from environment | Nightly exports, on-demand sync |
| `solution-import.yml` | Import to environment | Direct import without build |
| `solution-build.yml` | Build and pack | CI builds, artifact creation |
| `solution-validate.yml` | PR validation | Pull request checks |
| `solution-deploy.yml` | Full deployment | CD to QA/Prod |

### Plugin Workflows

| Workflow | Purpose | When to Use |
|----------|---------|-------------|
| `plugin-deploy.yml` | Deploy plugins | Plugin-only deployments |
| `plugin-extract.yml` | Extract registrations | Generate registration file |

### Complete Pipeline

| Workflow | Purpose | When to Use |
|----------|---------|-------------|
| `full-alm.yml` | Export, build, deploy | Full ALM automation |

## Example Workflows

### Nightly Export from Dev

```yaml
name: Nightly Export

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
  workflow_dispatch:

jobs:
  export:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-export.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      filter-noise: true
      commit-changes: true
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

### PR Validation

```yaml
name: PR Validation

on:
  pull_request:
    branches: [develop, main]

jobs:
  validate:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-validate.yml@v2
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

### Deploy to Production with Approval

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    environment: Prod  # Requires approval if configured
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-plugins: true
      package-type: Managed
      skip-if-same-version: true
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

### Multi-Environment Pipeline

```yaml
name: Release Pipeline

on:
  push:
    branches: [main]

jobs:
  build:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-build.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-plugins: true
      package-type: Managed

  deploy-qa:
    needs: build
    environment: QA
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      package-type: Managed
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}

  deploy-prod:
    needs: deploy-qa
    environment: Prod
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      package-type: Managed
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

## Using Composite Actions Directly

For more control, use composite actions directly in your workflows:

```yaml
name: Custom Workflow

on:
  workflow_dispatch:

jobs:
  custom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PAC CLI
        uses: joshsmithxrm/ppds-alm/.github/actions/setup-pac-cli@v2

      - name: Authenticate
        uses: joshsmithxrm/ppds-alm/.github/actions/pac-auth@v2
        with:
          environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
          tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
          client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
          client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}

      - name: Export solution
        uses: joshsmithxrm/ppds-alm/.github/actions/export-solution@v2
        with:
          solution-name: MySolution
          output-folder: solutions/MySolution/src

      - name: Analyze changes
        id: analyze
        uses: joshsmithxrm/ppds-alm/.github/actions/analyze-changes@v2
        with:
          solution-folder: solutions/MySolution/src

      - name: Commit if real changes
        if: steps.analyze.outputs.has-real-changes == 'true'
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git add -A
          git commit -m "chore: sync solution from Dev"
          git push
```

## Workflow Input Reference

### solution-deploy.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path to unpacked solution |
| `build-plugins` | No | `false` | Build .NET solution |
| `dotnet-solution-path` | No | Auto-detect | Path to .sln file |
| `package-type` | No | `Managed` | Managed or Unmanaged |
| `skip-if-same-version` | No | `true` | Skip if target has same version |
| `max-retries` | No | `3` | Retry attempts for transient failures |
| `settings-file` | No | Auto-detect | Deployment settings JSON path |

### solution-validate.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path to unpacked solution |
| `build-code` | No | `true` | Build .NET solution |
| `run-tests` | No | `true` | Run unit tests |
| `run-solution-checker` | No | `false` | Run Solution Checker |
| `checker-fail-level` | No | `High` | Fail threshold |
| `checker-geography` | No | `unitedstates` | Checker geography |

### solution-build.yml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name |
| `solution-folder` | Yes | - | Path to unpacked solution |
| `output-folder` | No | `./exports` | Output for packed files |
| `package-type` | No | `Both` | Managed, Unmanaged, or Both |
| `build-plugins` | No | `false` | Build .NET solution |
| `dotnet-solution-path` | No | Auto-detect | Path to .sln file |
| `run-tests` | No | `false` | Run unit tests |
| `configuration` | No | `Release` | Build configuration |

## Version Tags

Use version tags to ensure stability:

| Tag | Description | When to Use |
|-----|-------------|-------------|
| `@v2` | Latest v2.x | Recommended for production |
| `@v2.0.0` | Specific version | Maximum stability |
| `@main` | Latest development | Testing only |

```yaml
# Recommended: major version tag
uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2

# Locked to specific version
uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2.0.0
```

## Troubleshooting

### "Cannot find reusable workflow"

- Verify the repository path: `joshsmithxrm/ppds-alm`
- Check the workflow path matches exactly
- Ensure you're using a valid ref (`@v2`, `@main`, etc.)

### Authentication Failed

- Verify secrets are correctly configured
- Ensure the app registration has proper permissions
- Check the environment URL is correct and accessible

### Import Skipped (Version Match)

This is expected behavior when `skip-if-same-version: true` (default). The target environment already has the same or newer version. To force import:

```yaml
with:
  skip-if-same-version: false
```

### Solution Checker Failed

Review the checker output in the workflow summary. Common issues:
- Unsupported customizations
- Deprecated APIs
- Missing dependencies

Adjust `checker-fail-level` if needed:

```yaml
with:
  checker-fail-level: Critical  # Only fail on critical issues
```

See [Troubleshooting](./troubleshooting.md) for more help.

## See Also

- [Actions Reference](./actions-reference.md) - Detailed action documentation
- [Features Guide](./features.md) - Advanced feature explanations
- [Authentication](./authentication.md) - Credential setup guide
- [Migration Guide](./migration-v2.md) - Upgrading from v1

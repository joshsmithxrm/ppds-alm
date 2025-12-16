# Migration Guide: v1 to v2

This guide helps you upgrade from PPDS ALM v1 to v2.

## Overview

PPDS ALM v2 is a major release with significant architectural changes:

- **Composite Actions** - Modular, reusable building blocks
- **New Workflows** - Additional workflows for common scenarios
- **Enhanced Features** - Version comparison, retry logic, noise filtering
- **Breaking Changes** - Some input parameters have changed

## Quick Migration

### Minimum Changes Required

**Before (v1):**
```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/solution-import.yml@v1
    with:
      environment-url: 'https://myorg.crm.dynamics.com'
      solution-file: './exports/MySolution_managed.zip'
    secrets:
      client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
      client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
      tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

**After (v2):**
```yaml
jobs:
  deploy:
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

## Breaking Changes

### 1. Workflow Path Changes

| v1 Path | v2 Path |
|---------|---------|
| `.github/workflows/solution-import.yml` | `github/workflows/solution-import.yml` |
| `.github/workflows/solution-export.yml` | `github/workflows/solution-export.yml` |
| `.github/workflows/plugin-deploy.yml` | `github/workflows/plugin-deploy.yml` |

**Note:** The `.github` prefix is removed for reusable workflows in v2.

### 2. Authentication Parameter Changes

**v1:** Credentials passed as individual secrets
```yaml
secrets:
  client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
  client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
  tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

**v2:** Uses GitHub Environment variables and secrets
```yaml
secrets:
  environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
  tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
  client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
  client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

**Migration Steps:**
1. Create GitHub Environment (Settings > Environments)
2. Add variables: `POWERPLATFORM_ENVIRONMENT_URL`, `POWERPLATFORM_TENANT_ID`, `POWERPLATFORM_CLIENT_ID`
3. Add secret: `POWERPLATFORM_CLIENT_SECRET`
4. Update workflow to use `${{ vars.* }}` for variables

### 3. Input Parameter Changes

#### solution-import.yml / solution-deploy.yml

| v1 Parameter | v2 Parameter | Notes |
|--------------|--------------|-------|
| `solution-file` | `solution-path` | Renamed |
| `environment-url` (input) | `environment-url` (secret) | Now a secret |
| `publish-changes` | `publish-changes` | Unchanged |
| N/A | `solution-name` | New (required for version check) |
| N/A | `skip-if-same-version` | New (default: true) |
| N/A | `max-retries` | New (default: 3) |
| N/A | `settings-file` | New |

#### solution-export.yml

| v1 Parameter | v2 Parameter | Notes |
|--------------|--------------|-------|
| `solution-name` | `solution-name` | Unchanged |
| `output-path` | `solution-folder` | Renamed |
| `managed` | N/A | Removed (always exports both) |
| N/A | `filter-noise` | New |
| N/A | `commit-changes` | New |

#### plugin-deploy.yml

| v1 Parameter | v2 Parameter | Notes |
|--------------|--------------|-------|
| `registration-file` | `registration-file` | Unchanged |
| `environment-url` (input) | `environment-url` (secret) | Now a secret |
| `detect-drift` | `detect-drift` | Unchanged |

### 4. Behavioral Changes

#### Version Comparison (New Default)

v2 skips imports when the target environment has the same or newer version.

**Impact:** Deployments may be "skipped" where v1 would have imported.

**To Restore v1 Behavior:**
```yaml
with:
  skip-if-same-version: false
```

#### Retry Logic (New Default)

v2 retries transient failures (concurrent import conflicts).

**Impact:** Failed imports may take longer before reporting failure.

**To Restore v1 Behavior:**
```yaml
with:
  max-retries: 0
```

#### Noise Filtering (New Feature)

v2's `solution-export.yml` can filter volatile changes.

**Impact:** Some exports may result in "no changes" where v1 would commit.

**To Restore v1 Behavior:**
```yaml
with:
  filter-noise: false
```

### 5. Removed Features

| Feature | Replacement |
|---------|-------------|
| PPDS.Tools for solution ops | PAC CLI (built-in) |
| `full-alm.yml` v1 structure | `solution-deploy.yml` with `build-plugins` |

Plugin operations (`plugin-deploy.yml`, `plugin-extract.yml`) still use PPDS.Tools.

## New Features to Adopt

### Composite Actions

Use granular actions for custom workflows:

```yaml
steps:
  - uses: joshsmithxrm/ppds-alm/.github/actions/setup-pac-cli@v2
  - uses: joshsmithxrm/ppds-alm/.github/actions/pac-auth@v2
  - uses: joshsmithxrm/ppds-alm/.github/actions/export-solution@v2
  # ... more actions
```

### Solution Validation

New workflow for PR validation:

```yaml
jobs:
  validate:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-validate.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      run-solution-checker: true
```

### Build Pipeline

New workflow for .NET solution builds:

```yaml
jobs:
  build:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-build.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-plugins: true
      run-tests: true
```

### Deployment Settings

Auto-detection of environment-specific configuration:

```yaml
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      # settings-file auto-detected from ./config/
```

## Step-by-Step Migration

### Step 1: Update Repository Configuration

1. Create GitHub Environments for each target:
   - Go to Settings > Environments
   - Create `Dev`, `QA`, `Prod` (as needed)

2. Move secrets to environment variables:
   - `POWERPLATFORM_ENVIRONMENT_URL` (variable)
   - `POWERPLATFORM_TENANT_ID` (variable)
   - `POWERPLATFORM_CLIENT_ID` (variable)
   - `POWERPLATFORM_CLIENT_SECRET` (secret)

### Step 2: Update Workflow References

Change version tags:
```yaml
# Before
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-import.yml@v1

# After
uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
```

### Step 3: Update Input Parameters

Map v1 parameters to v2 equivalents using the tables above.

### Step 4: Update Secret References

```yaml
# Before
secrets:
  client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}

# After
secrets:
  client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
  client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

### Step 5: Test in Non-Production

1. Create a test branch
2. Update one workflow
3. Run against Dev or QA environment
4. Verify expected behavior

### Step 6: Roll Out to All Workflows

Once tested, update remaining workflows.

## Rollback Plan

If issues arise:
1. Keep v1 reference available in a branch
2. Pin to `@v1.0.0` for specific version
3. Report issues at: https://github.com/joshsmithxrm/ppds-alm/issues

## Example: Complete Migration

### v1 Workflow

```yaml
name: Deploy Solution

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy
        uses: joshsmithxrm/ppds-alm/.github/workflows/solution-import.yml@v1
        with:
          environment-url: 'https://myorg.crm.dynamics.com'
          solution-file: './solutions/MySolution_managed.zip'
          publish-changes: true
        secrets:
          client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
          client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
          tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

### v2 Workflow

```yaml
name: Deploy Solution

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2
    with:
      solution-name: MySolution
      solution-folder: solutions/MySolution/src
      build-plugins: false
      package-type: Managed
      skip-if-same-version: true
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

## See Also

- [CHANGELOG](../CHANGELOG.md) - Full list of changes
- [GitHub Quickstart](./github-quickstart.md) - v2 getting started guide
- [Actions Reference](./actions-reference.md) - Detailed action documentation

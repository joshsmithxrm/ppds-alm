# Consumption Guide

This guide helps you choose between reusable workflows and composite actions based on your needs.

---

## Quick Decision Matrix

| Scenario | Recommendation |
|----------|----------------|
| New to Power Platform ALM | **Workflows** - simpler to start |
| Standard CI/CD pipeline | **Workflows** - handles common cases |
| Custom orchestration | **Actions** - more flexible |
| Multi-solution pipelines | **Actions** - compose your own flow |
| Quick prototyping | **Workflows** - less configuration |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  YOUR WORKFLOW                                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Option A: Reusable Workflows (High-level)                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  solution-deploy.yml                                     │    │
│  │  ┌──────────────────────────────────────────────────┐   │    │
│  │  │  Internally calls:                                │   │    │
│  │  │  • build-solution action                         │   │    │
│  │  │  • pack-solution action                          │   │    │
│  │  │  • import-solution action                        │   │    │
│  │  └──────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Option B: Composite Actions (Low-level)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐     │
│  │build-solution│→ │pack-solution│→ │import-solution     │     │
│  └─────────────┘  └─────────────┘  └─────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Reusable Workflows

### What They Are

Reusable workflows are complete CI/CD pipelines that handle multi-step processes. You call them with `uses:` at the job level.

### When to Use

- **Standard ALM scenarios** - Deploy to QA on merge, deploy to Prod on release
- **Quick setup** - Minimal configuration, sensible defaults
- **Team standardization** - Consistent processes across projects

### Example

```yaml
name: Deploy to QA

on:
  push:
    branches: [develop]

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

### Available Workflows

| Workflow | Purpose |
|----------|---------|
| `solution-export.yml` | Export and unpack from environment |
| `solution-import.yml` | Import with version checking |
| `solution-build.yml` | Build and pack solution |
| `solution-validate.yml` | PR validation with Solution Checker |
| `solution-deploy.yml` | Build, pack, and deploy |
| `solution-promote.yml` | Promote between environments |
| `plugin-extract.yml` | Extract plugin registrations |
| `plugin-deploy.yml` | Deploy plugins with drift detection |
| `azure-deploy.yml` | Deploy Azure infrastructure |

See [WORKFLOWS_REFERENCE.md](./WORKFLOWS_REFERENCE.md) for detailed documentation.

---

## Composite Actions

### What They Are

Composite actions are single-purpose building blocks. You call them with `uses:` at the step level within your own job.

### When to Use

- **Custom orchestration** - Need steps not covered by workflows
- **Multi-solution pipelines** - Complex dependency chains
- **Conditional logic** - Different behavior based on context
- **Integration with other tools** - Mix with non-Power Platform steps

### Example

```yaml
name: Custom Pipeline

on:
  workflow_dispatch:

jobs:
  custom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PAC CLI
        uses: joshsmithxrm/ppds-alm/.github/actions/setup-pac-cli@v1

      - name: Export solution
        uses: joshsmithxrm/ppds-alm/.github/actions/export-solution@v1
        with:
          solution-name: MySolution
          output-folder: solutions/MySolution/src
          environment-url: ${{ secrets.ENVIRONMENT_URL }}
          tenant-id: ${{ secrets.TENANT_ID }}
          client-id: ${{ secrets.CLIENT_ID }}
          client-secret: ${{ secrets.CLIENT_SECRET }}

      - name: Custom processing step
        run: |
          echo "Do something custom here..."

      - name: Analyze for noise
        id: analyze
        uses: joshsmithxrm/ppds-alm/.github/actions/analyze-changes@v1
        with:
          solution-folder: solutions/MySolution/src

      - name: Commit if real changes
        if: steps.analyze.outputs.has-real-changes == 'true'
        run: |
          git add -A
          git commit -m "chore: sync solution"
          git push
```

### Available Actions

| Action | Purpose |
|--------|---------|
| `setup-pac-cli` | Install PAC CLI |
| `pac-auth` | Authenticate to environment |
| `export-solution` | Export and unpack |
| `import-solution` | Import with retry logic |
| `pack-solution` | Pack to zip |
| `build-solution` | Build .NET solution |
| `check-solution` | Run Solution Checker |
| `analyze-changes` | Filter noise from exports |
| `copy-plugin-assemblies` | Copy DLLs to solution |
| `copy-plugin-packages` | Copy packages to solution |

See [ACTIONS_REFERENCE.md](./ACTIONS_REFERENCE.md) for detailed documentation.

---

## Comparison

| Aspect | Workflows | Actions |
|--------|-----------|---------|
| Configuration | Minimal | More detailed |
| Flexibility | Limited to inputs | Full control |
| Error handling | Built-in retry | You implement |
| Artifacts | Auto-uploaded | You manage |
| Summaries | Auto-generated | You generate |
| Maintenance | Less code | More code |

---

## Common Patterns

### Pattern 1: Standard Pipeline (Use Workflows)

```yaml
# PR validation
validate:
  uses: .../solution-validate.yml@v1

# Deploy on merge
deploy-qa:
  uses: .../solution-deploy.yml@v1

# Deploy on release
deploy-prod:
  uses: .../solution-deploy.yml@v1
```

### Pattern 2: Multi-Solution (Use Actions)

```yaml
jobs:
  build-all:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        solution: [Core, Extensions, Plugins]
    steps:
      - uses: actions/checkout@v4
      - uses: .../setup-pac-cli@v1
      - uses: .../pack-solution@v1
        with:
          solution-name: ${{ matrix.solution }}
          # ...
```

### Pattern 3: Mixed Approach

```yaml
jobs:
  # Use workflow for standard parts
  build:
    uses: .../solution-build.yml@v1

  # Use actions for custom parts
  custom-deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
      - uses: .../import-solution@v1
        with:
          # Custom logic here
```

---

## Migration Guide

### From Workflows to Actions

If you outgrow workflows:

1. Review the workflow source to understand what it does
2. Create your own job with the same steps using actions
3. Add your custom logic between actions
4. Test thoroughly before switching

### From Actions to Workflows

If your pipeline is too complex:

1. Check if a workflow covers your use case
2. Replace your multi-step job with a single workflow call
3. Remove action-specific configuration
4. Test that outputs match your needs

---

## Best Practices

### 1. Start Simple

Begin with workflows. Only move to actions when you hit limitations.

### 2. Version Your References

Always use version tags, not `@main`:

```yaml
# Good
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1

# Risky
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@main
```

### 3. Use Environments for Secrets

Configure GitHub Environments for environment-specific secrets:

```yaml
jobs:
  deploy-qa:
    environment: QA
    uses: .../solution-deploy.yml@v1
    secrets:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
```

### 4. Review Workflow Outputs

Workflows provide outputs for downstream jobs:

```yaml
jobs:
  build:
    uses: .../solution-build.yml@v1

  notify:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Version ${{ needs.build.outputs.version }} built"
```

---

## See Also

- [WORKFLOWS_REFERENCE.md](./WORKFLOWS_REFERENCE.md) - All workflows documented
- [ACTIONS_REFERENCE.md](./ACTIONS_REFERENCE.md) - All actions documented
- [GITHUB_QUICKSTART.md](./GITHUB_QUICKSTART.md) - Getting started
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues

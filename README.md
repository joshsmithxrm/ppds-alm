# PPDS ALM

CI/CD templates for Power Platform Application Lifecycle Management (ALM).

Part of the [Power Platform Developer Suite](https://github.com/joshsmithxrm) ecosystem.

## Quick Start

### GitHub Actions

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

## Reusable Workflows

| Workflow | Purpose |
|----------|---------|
| [`solution-export.yml`](./.github/workflows/solution-export.yml) | Export solution from environment with noise filtering |
| [`solution-import.yml`](./.github/workflows/solution-import.yml) | Import solution with version check and retry logic |
| [`solution-build.yml`](./.github/workflows/solution-build.yml) | Build .NET code and pack solution |
| [`solution-validate.yml`](./.github/workflows/solution-validate.yml) | PR validation with build, pack, and Solution Checker |
| [`solution-deploy.yml`](./.github/workflows/solution-deploy.yml) | Full deployment: build, pack, import |
| [`plugin-deploy.yml`](./.github/workflows/plugin-deploy.yml) | Deploy plugins using PPDS.Cli |
| [`plugin-extract.yml`](./.github/workflows/plugin-extract.yml) | Extract plugin registrations from assembly |
| [`solution-promote.yml`](./.github/workflows/solution-promote.yml) | Promote solution between environments (export, build, deploy) |
| [`azure-deploy.yml`](./.github/workflows/azure-deploy.yml) | Deploy Azure integration resources |

## Composite Actions

Granular, reusable actions for building custom workflows:

| Action | Purpose |
|--------|---------|
| [`setup-pac-cli`](./.github/actions/setup-pac-cli) | Install .NET SDK and Power Platform CLI |
| [`pac-auth`](./.github/actions/pac-auth) | Authenticate to Power Platform environment |
| [`export-solution`](./.github/actions/export-solution) | Export and unpack solution |
| [`import-solution`](./.github/actions/import-solution) | Import with version check and retry |
| [`pack-solution`](./.github/actions/pack-solution) | Pack solution from source |
| [`build-solution`](./.github/actions/build-solution) | Build .NET solution with tests |
| [`check-solution`](./.github/actions/check-solution) | Run PowerApps Solution Checker |
| [`analyze-changes`](./.github/actions/analyze-changes) | Filter noise from exports |
| [`copy-plugin-assemblies`](./.github/actions/copy-plugin-assemblies) | Copy built DLLs to solution |
| [`copy-plugin-packages`](./.github/actions/copy-plugin-packages) | Copy NuGet packages to solution |

See [Actions Reference](./docs/ACTIONS_REFERENCE.md) for detailed documentation.

## Key Features

### Smart Import

The import action automatically:
- **Compares versions** - Skips import if target has same or newer version
- **Retries transient failures** - Handles concurrent import conflicts with configurable retry
- **Applies deployment settings** - Auto-detects environment-specific configuration files

```yaml
- uses: joshsmithxrm/ppds-alm/.github/actions/import-solution@v1
  with:
    solution-path: ./exports/MySolution_managed.zip
    solution-name: MySolution
    skip-if-same-version: 'true'
    max-retries: '3'
    settings-file: ./config/qa.deploymentsettings.json
```

### Noise Filtering

Solution exports often contain volatile changes that aren't real customizations:
- Solution.xml version timestamps
- Canvas app random URI suffixes
- Workflow session IDs
- Whitespace-only changes

The `analyze-changes` action filters these, preventing unnecessary commits.

### Solution Checker Integration

Validate solution quality before deployment:

```yaml
- uses: joshsmithxrm/ppds-alm/.github/actions/check-solution@v1
  with:
    solution-path: ./exports/MySolution_managed.zip
    fail-on-level: High  # Critical, High, Medium, Low, Informational
    geography: unitedstates
```

## Documentation

### Getting Started
- [GitHub Actions Quickstart](./docs/GITHUB_QUICKSTART.md)
- [Authentication Setup](./docs/AUTHENTICATION.md)

### Reference
- [Workflows Reference](./docs/WORKFLOWS_REFERENCE.md) - All reusable workflows documented
- [Actions Reference](./docs/ACTIONS_REFERENCE.md) - All composite actions documented
- [Consumption Guide](./docs/CONSUMPTION_GUIDE.md) - When to use actions vs workflows
- [Features Guide](./docs/FEATURES.md) - Deep dive into advanced features
- [Troubleshooting](./docs/TROUBLESHOOTING.md)

### Azure Integration
- [Azure Integration](./docs/AZURE_INTEGRATION.md) - Bicep modules and naming
- [Azure OIDC Setup](./docs/AZURE_OIDC_SETUP.md) - GitHub Actions authentication
- [Azure Coordination](./docs/AZURE_COORDINATION.md) - Coordinating Azure and Dataverse deployments

### Strategy Guides
- [ALM Overview](./docs/strategy/ALM_OVERVIEW.md) - Philosophy and approach
- [Branching Strategy](./docs/strategy/BRANCHING_STRATEGY.md) - Recommended git workflow
- [Environment Strategy](./docs/strategy/ENVIRONMENT_STRATEGY.md) - Dev/QA/Prod patterns

## Repository Structure

```
ppds-alm/
├── .github/
│   ├── actions/                    # Composite actions
│   │   ├── setup-pac-cli/
│   │   ├── pac-auth/
│   │   ├── export-solution/
│   │   ├── import-solution/
│   │   ├── pack-solution/
│   │   ├── build-solution/
│   │   ├── check-solution/
│   │   ├── analyze-changes/
│   │   ├── copy-plugin-assemblies/
│   │   └── copy-plugin-packages/
│   └── workflows/                  # All workflows
│       ├── _ci.yml                 # CI for this repo (internal)
│       ├── solution-export.yml     # Reusable workflows (workflow_call)
│       ├── solution-import.yml
│       ├── solution-build.yml
│       ├── solution-validate.yml
│       ├── solution-deploy.yml
│       ├── plugin-deploy.yml
│       ├── plugin-extract.yml
│       ├── solution-promote.yml
│       └── azure-deploy.yml
├── bicep/                          # Azure Bicep modules
├── docs/
├── CHANGELOG.md
└── README.md
```

## Compatibility

| ALM Version | Dependencies |
|-------------|--------------|
| v1.0.x | PPDS.Cli (for plugins), PAC CLI (for solutions) |

## Versioning

Use version tags for stability:

| Tag | Description | Recommendation |
|-----|-------------|----------------|
| `@v1` | Latest v1.x release | Recommended for production |
| `@v1.0.0` | Specific version | Maximum stability |
| `@main` | Latest development | Not recommended for production |

## PPDS Ecosystem

| Repository | Purpose | Install |
|------------|---------|---------|
| [power-platform-developer-suite](https://github.com/joshsmithxrm/power-platform-developer-suite) | SDK + CLI + TUI + Extension + MCP | NuGet / VS Code Marketplace |
| [ppds-tools](https://github.com/joshsmithxrm/ppds-tools) | PowerShell Module | `Install-Module PPDS.Tools` |
| **ppds-alm** | CI/CD Templates | Reference in pipelines |
| [ppds-demo](https://github.com/joshsmithxrm/ppds-demo) | Reference Implementation | Clone |
| [ppds-orchestration](https://github.com/joshsmithxrm/ppds-orchestration) | Parallel Claude Code Sessions | npm |

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run actionlint on GitHub Actions workflows
5. Test with actual CI/CD environment
6. Submit a pull request

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Support

- [Report Issues](https://github.com/joshsmithxrm/ppds-alm/issues)
- [Documentation](./docs/)

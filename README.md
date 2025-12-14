# PPDS ALM

CI/CD pipeline templates for Power Platform and Dataverse development.

Part of the [Power Platform Developer Suite](https://github.com/joshsmithxrm) ecosystem.

## Overview

PPDS ALM provides reusable pipeline templates for both **GitHub Actions** and **Azure DevOps**, enabling automated:

- Plugin deployment with drift detection
- Plugin registration extraction
- Solution export and import
- Complete ALM workflows

## Quick Start

### GitHub Actions

```yaml
name: Deploy Plugins

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1
    with:
      environment-url: 'https://myorg.crm.dynamics.com'
      registration-file: './registrations.json'
    secrets:
      client-id: ${{ secrets.DATAVERSE_CLIENT_ID }}
      client-secret: ${{ secrets.DATAVERSE_CLIENT_SECRET }}
      tenant-id: ${{ secrets.DATAVERSE_TENANT_ID }}
```

### Azure DevOps

```yaml
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
      registrationFile: './registrations.json'
      serviceConnection: 'Dataverse Production'
```

## Available Templates

### GitHub Actions (Reusable Workflows)

| Workflow | Description |
|----------|-------------|
| `plugin-deploy.yml` | Deploy plugins to Dataverse environment |
| `plugin-extract.yml` | Extract plugin registrations from compiled assembly |
| `solution-export.yml` | Export solution from Dataverse |
| `solution-import.yml` | Import solution to Dataverse |
| `full-alm.yml` | Complete ALM pipeline (export, import, deploy) |

### Azure DevOps Templates

| Template | Description |
|----------|-------------|
| `plugin-deploy.yml` | Deploy plugins to Dataverse environment |
| `plugin-extract.yml` | Extract plugin registrations from compiled assembly |
| `solution-export.yml` | Export solution from Dataverse |
| `solution-import.yml` | Import solution to Dataverse |
| `full-alm.yml` | Complete ALM pipeline (export, import, deploy) |

## Documentation

- [GitHub Actions Quickstart](./docs/github-quickstart.md)
- [Azure DevOps Quickstart](./docs/azure-devops-quickstart.md)
- [Authentication Setup](./docs/authentication.md)
- [Troubleshooting](./docs/troubleshooting.md)

## Prerequisites

### For Plugin Operations
- [PPDS.Tools](https://github.com/joshsmithxrm/ppds-tools) PowerShell module
- Azure AD app registration with Dataverse access

### For Solution Operations
- Power Platform CLI (installed automatically)
- Azure AD app registration with Dataverse access

## Repository Structure

```
ppds-alm/
├── .github/
│   └── workflows/
│       └── ci.yml                    # CI for this repo
│
├── github/
│   └── workflows/                    # Reusable workflows for consumers
│       ├── plugin-deploy.yml
│       ├── plugin-extract.yml
│       ├── solution-export.yml
│       ├── solution-import.yml
│       └── full-alm.yml
│
├── azure-devops/
│   ├── templates/                    # Templates for consumers
│   │   ├── plugin-deploy.yml
│   │   ├── plugin-extract.yml
│   │   ├── solution-export.yml
│   │   ├── solution-import.yml
│   │   └── full-alm.yml
│   └── examples/
│       ├── starter-pipeline.yml
│       └── advanced-pipeline.yml
│
├── docs/
│   ├── github-quickstart.md
│   ├── azure-devops-quickstart.md
│   ├── authentication.md
│   └── troubleshooting.md
│
├── README.md
├── LICENSE
└── CHANGELOG.md
```

## PPDS Ecosystem

| Repository | Purpose | Install |
|------------|---------|---------|
| [power-platform-developer-suite](https://github.com/joshsmithxrm/power-platform-developer-suite) | VS Code Extension | VS Code Marketplace |
| [ppds-sdk](https://github.com/joshsmithxrm/ppds-sdk) | .NET Plugin Attributes | `dotnet add package PPDS.Plugins` |
| [ppds-tools](https://github.com/joshsmithxrm/ppds-tools) | PowerShell Module | `Install-Module PPDS.Tools` |
| **ppds-alm** | CI/CD Templates | Reference in pipelines |
| [ppds-demo](https://github.com/joshsmithxrm/ppds-demo) | Reference Implementation | Clone |

## Versioning

Use version tags for stability:

- `@v1` - Latest v1.x release (recommended for production)
- `@v1.0.0` - Specific version
- `@main` - Latest development (not recommended for production)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both GitHub Actions and Azure DevOps
5. Submit a pull request

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Support

- [Report Issues](https://github.com/joshsmithxrm/ppds-alm/issues)
- [Documentation](./docs/)

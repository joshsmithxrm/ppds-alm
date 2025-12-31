# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-12-31

Initial release of ppds-alm - reusable GitHub Actions workflows and composite actions for Power Platform ALM.

### Composite Actions

Ten self-contained actions for Power Platform CI/CD:

| Action | Description |
|--------|-------------|
| `setup-pac-cli` | Install .NET SDK and Power Platform CLI with version pinning |
| `pac-auth` | Authenticate to environment (self-contained with automatic cleanup) |
| `export-solution` | Export and unpack solution (self-contained auth, includes Linux bug workaround) |
| `import-solution` | Import solution with version check, retry logic, upgrade support, and fresh auth before publish |
| `pack-solution` | Pack solution from unpacked source files |
| `build-solution` | Build .NET solution with optional test execution |
| `check-solution` | Run Solution Checker with configurable severity thresholds |
| `analyze-changes` | Filter noise from solution exports (version stamps, session IDs, etc.) |
| `copy-plugin-assemblies` | Copy classic plugin DLLs to solution folder |
| `copy-plugin-packages` | Copy plugin packages (.nupkg) to solution folder |

### Reusable Workflows

Nine workflows for common ALM scenarios:

| Workflow | Description |
|----------|-------------|
| `solution-export.yml` | Export solution with optional noise filtering and version stamping |
| `solution-import.yml` | Import solution with version comparison and retry logic |
| `solution-build.yml` | Build .NET code and pack solution with artifact upload |
| `solution-validate.yml` | PR validation with build, pack, tests, and Solution Checker |
| `solution-deploy.yml` | Full deployment: build, pack, and import with settings auto-detection |
| `solution-promote.yml` | Promote solution from source to target environment |
| `plugin-extract.yml` | Extract plugin registrations from compiled assembly |
| `plugin-deploy.yml` | Deploy plugins with drift detection |
| `azure-deploy.yml` | Deploy Azure integration infrastructure via Bicep |

### Azure Integration

- **Bicep Modules** - Reusable infrastructure-as-code for Dataverse integrations
  - `log-analytics.bicep` - Log Analytics Workspace
  - `application-insights.bicep` - Application Insights with Log Analytics integration
  - `storage-account.bicep` - Storage Account for Function Apps
  - `app-service-plan.bicep` - Shared hosting plan
  - `app-service.bicep` - App Service for Web API hosting
  - `function-app.bicep` - Azure Function App with managed identity
  - `service-bus.bicep` - Service Bus namespace with queue creation
  - `dataverse-integration.bicep` - Composite module wiring all resources together

- **CAF Naming** - All Bicep modules follow Microsoft Cloud Adoption Framework naming conventions

### Key Features

- **Self-Contained Auth** - Actions manage their own authentication lifecycle (clear → create → work → clear)
- **Smart Import** - Version comparison skips import if target has same or newer version
- **Solution Upgrades** - Support for `--stage-and-upgrade` and `--import-as-holding`
- **Retry Logic** - Configurable retry for transient failures (concurrent import conflicts)
- **Noise Filtering** - Automatic filtering of volatile export changes
- **Solution Checker** - Quality validation with severity-based pass/fail thresholds
- **Deployment Settings** - Auto-detection and application of environment-specific configuration
- **Linux Compatibility** - Workarounds for PAC CLI bugs on Linux runners

### Documentation

- Strategy guides (ALM Overview, Branching Strategy, Environment Strategy)
- Comprehensive action and workflow references
- Authentication setup guide
- Azure OIDC setup guide
- Azure coordination guide
- Consumption guide (actions vs workflows)
- Troubleshooting guide

### Dependencies

- Power Platform CLI (installed automatically by `setup-pac-cli`)
- .NET SDK 8.x (installed automatically)
- PPDS.Cli (for plugin workflows)

[Unreleased]: https://github.com/joshsmithxrm/ppds-alm/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/joshsmithxrm/ppds-alm/releases/tag/v1.0.0

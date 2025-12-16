# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025-12-16

### Added

#### Composite Actions (10 new actions)

- **`setup-pac-cli`** - Install .NET SDK and Power Platform CLI with version pinning support
- **`pac-auth`** - Authenticate to Power Platform environment using service principal
- **`export-solution`** - Export and unpack solution with PAC CLI Linux bug workaround
- **`import-solution`** - Import with version comparison, smart retry logic, and deployment settings
- **`pack-solution`** - Pack solution from unpacked source files
- **`build-solution`** - Build .NET solution with optional test execution
- **`check-solution`** - Run PowerApps Solution Checker with configurable severity thresholds
- **`analyze-changes`** - Filter noise from solution exports (version stamps, session IDs, etc.)
- **`copy-plugin-assemblies`** - Copy classic plugin DLLs to solution folder
- **`copy-plugin-packages`** - Copy plugin packages (.nupkg) to solution folder

#### New Reusable Workflows

- **`solution-build.yml`** - Build .NET code and pack solution with artifact upload
- **`solution-validate.yml`** - PR validation with build, pack, tests, and Solution Checker
- **`solution-deploy.yml`** - Full deployment workflow: build, pack, import with version check

#### Enterprise Features

- **Smart Import** - Version comparison skips import if target has same or newer version
- **Retry Logic** - Configurable retry for transient failures (concurrent import conflicts)
- **Noise Filtering** - Automatic filtering of volatile export changes:
  - Solution.xml version-only changes
  - Canvas App DocumentUri/BackgroundImageUri random suffixes
  - Workflow session ID regeneration
  - Whitespace-only changes
  - Git R100 renames (100% identical content)
  - MissingDependency version reference updates
- **Solution Checker Integration** - Quality validation with severity-based pass/fail
- **Deployment Settings** - Auto-detection and application of environment-specific configuration
- **Build Pipeline** - Full .NET solution build with plugin assembly/package copy

#### Documentation

- Strategy guides (ALM Overview, Branching Strategy, Environment Strategy)
- Comprehensive actions reference
- Features deep-dive documentation
- v2 migration guide

### Changed

#### Updated Workflows

- **`solution-export.yml`** - Now uses composite actions, adds noise filtering option
- **`solution-import.yml`** - Now uses composite actions, adds version check and retry
- **`plugin-deploy.yml`** - Updated inputs for consistency
- **`plugin-extract.yml`** - Updated inputs for consistency
- **`full-alm.yml`** - Orchestrates new composite actions

#### Architecture Changes

- Moved from monolithic workflows to composable actions
- Solution operations now use PAC CLI directly (more reliable than PPDS.Tools for solution ops)
- Plugin operations continue to use PPDS.Tools for advanced features

### Breaking Changes

See [Migration Guide](./docs/migration-v2.md) for detailed upgrade instructions.

#### Input Parameter Changes

| v1 Parameter | v2 Parameter | Notes |
|--------------|--------------|-------|
| `environment-url` (input) | `environment-url` (secret) | Now passed as secret |
| `registration-file` | Removed | Plugin workflows restructured |

#### Behavioral Changes

- **Version Comparison** - Import now skips if target has same/newer version (opt-out available)
- **Retry Logic** - Transient failures now retry (may delay failure detection)
- **Noise Filtering** - Exports may result in "no changes" where before there were changes

#### Removed

- Direct PPDS.Tools usage for solution export/import (replaced with PAC CLI)
- Some legacy input parameters (see migration guide)

### Dependencies

- Requires Power Platform CLI (installed automatically)
- Optional: [PPDS.Tools](https://github.com/joshsmithxrm/ppds-tools) for plugin operations
- .NET SDK 8.x (installed automatically)

---

## [1.0.0] - 2025-12-13

### Added

- Initial release of PPDS ALM templates

#### GitHub Actions Reusable Workflows
- `plugin-deploy.yml` - Deploy plugins to Dataverse with drift detection
- `plugin-extract.yml` - Extract plugin registrations from compiled assemblies
- `solution-export.yml` - Export solutions from Dataverse environments
- `solution-import.yml` - Import solutions to Dataverse environments
- `full-alm.yml` - Complete ALM pipeline combining export, import, and plugin deployment

#### Azure DevOps Templates
- `plugin-deploy.yml` - Deploy plugins using PPDS.Tools module
- `plugin-extract.yml` - Extract plugin registrations
- `solution-export.yml` - Export solutions using Power Platform Build Tools
- `solution-import.yml` - Import solutions with customization publish
- `full-alm.yml` - Multi-stage ALM pipeline

#### Documentation
- GitHub Actions quickstart guide
- Azure DevOps quickstart guide
- Authentication setup guide
- Troubleshooting guide

#### Examples
- `starter-pipeline.yml` - Basic Azure DevOps pipeline example
- `advanced-pipeline.yml` - Multi-environment pipeline with approvals

### Dependencies
- Requires [PPDS.Tools](https://github.com/joshsmithxrm/ppds-tools) PowerShell module
- Uses Microsoft Power Platform CLI for solution operations
- Uses Microsoft Power Platform Build Tools for Azure DevOps

[Unreleased]: https://github.com/joshsmithxrm/ppds-alm/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/joshsmithxrm/ppds-alm/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/joshsmithxrm/ppds-alm/releases/tag/v1.0.0

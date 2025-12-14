# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/joshsmithxrm/ppds-alm/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/joshsmithxrm/ppds-alm/releases/tag/v1.0.0

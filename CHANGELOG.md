# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-12-26

Initial release of ppds-alm - reusable GitHub Actions and workflows for Power Platform ALM.

### Composite Actions

Ten self-contained actions for Power Platform CI/CD:

| Action | Description |
|--------|-------------|
| `setup-pac-cli` | Install .NET SDK and Power Platform CLI with version pinning |
| `pac-auth` | Authenticate to environment (self-contained with automatic cleanup) |
| `export-solution` | Export and unpack solution (self-contained auth, includes Linux bug workaround) |
| `import-solution` | Import solution with version check, retry logic, and fresh auth before publish |
| `pack-solution` | Pack solution from unpacked source files |
| `build-solution` | Build .NET solution with optional test execution |
| `check-solution` | Run Solution Checker with configurable severity thresholds (anonymous mode) |
| `analyze-changes` | Filter noise from solution exports (version stamps, session IDs, etc.) |
| `copy-plugin-assemblies` | Copy classic plugin DLLs to solution folder |
| `copy-plugin-packages` | Copy plugin packages (.nupkg) to solution folder |

### Reusable Workflows

- **`solution-export.yml`** - Export solution with optional noise filtering and version stamping
- **`solution-import.yml`** - Import solution with version comparison and retry logic
- **`solution-deploy.yml`** - Full deployment: build, pack, and import with settings auto-detection
- **`solution-build.yml`** - Build .NET code and pack solution with artifact upload
- **`solution-validate.yml`** - PR validation with build, pack, tests, and Solution Checker
- **`full-alm.yml`** - Complete ALM pipeline: export, build, pack, and deploy

### Key Features

- **Self-Contained Auth** - Actions manage their own authentication lifecycle following Microsoft's pattern (clear → create → work → clear), preventing token expiration issues on long-running operations
- **Smart Import** - Version comparison skips import if target has same or newer version
- **Retry Logic** - Configurable retry for transient failures (concurrent import conflicts)
- **Noise Filtering** - Automatic filtering of volatile export changes (version stamps, canvas app URIs, workflow session IDs)
- **Solution Checker** - Quality validation with severity-based pass/fail thresholds
- **Deployment Settings** - Auto-detection and application of environment-specific configuration
- **Linux Compatibility** - Workarounds for PAC CLI bugs on Linux runners (--allowDelete, libsecret)

### Documentation

- Strategy guides (ALM Overview, Branching Strategy, Environment Strategy)
- Comprehensive actions reference
- Authentication setup guide
- Troubleshooting guide

### Dependencies

- Power Platform CLI (installed automatically by `setup-pac-cli`)
- .NET SDK 8.x (installed automatically)
- Optional: [PPDS.Tools](https://github.com/joshsmithxrm/ppds-tools) for advanced plugin operations

[Unreleased]: https://github.com/joshsmithxrm/ppds-alm/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/joshsmithxrm/ppds-alm/releases/tag/v1.0.0

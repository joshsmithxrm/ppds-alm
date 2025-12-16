# PPDS ALM v2 Migration Checklist

This checklist tracks the migration of PPDS ALM from v1 to v2 architecture.

## Overview

The v2 architecture introduces:
- Composite actions for modular, reusable building blocks
- Smart import with version comparison and retry logic
- Noise filtering for cleaner solution exports
- Solution Checker integration
- Full .NET build pipeline support

## Migration Phases

### Phase 1: Composite Actions

**Status: COMPLETE**

- [x] `setup-pac-cli` - Install .NET SDK and PAC CLI
- [x] `pac-auth` - Authenticate to Power Platform
- [x] `export-solution` - Export and unpack solution
- [x] `import-solution` - Import with version check and retry
- [x] `pack-solution` - Pack solution from source
- [x] `build-solution` - Build .NET solution
- [x] `check-solution` - Run Solution Checker
- [x] `analyze-changes` - Filter noise from exports
- [x] `copy-plugin-assemblies` - Copy plugin DLLs
- [x] `copy-plugin-packages` - Copy plugin packages

### Phase 2: Reusable Workflows

**Status: COMPLETE**

- [x] `solution-export.yml` - Export workflow
- [x] `solution-import.yml` - Import workflow
- [x] `solution-build.yml` - Build and pack workflow
- [x] `solution-validate.yml` - PR validation workflow
- [x] `solution-deploy.yml` - Full deployment workflow
- [x] Update existing plugin workflows for v2 compatibility
- [x] Update `full-alm.yml` to use new architecture

### Phase 3: Azure DevOps Templates

**Status: PLANNED**

- [ ] Update `solution-export.yml` template
- [ ] Update `solution-import.yml` template
- [ ] Create `solution-build.yml` template
- [ ] Create `solution-validate.yml` template
- [ ] Create `solution-deploy.yml` template
- [ ] Update plugin templates
- [ ] Update example pipelines

### Phase 4: Documentation

**Status: COMPLETE**

- [x] Update README.md with v2 features
- [x] Update CHANGELOG.md with v2.0.0 entry
- [x] Update docs/github-quickstart.md
- [x] Update docs/azure-devops-quickstart.md
- [x] Create docs/actions-reference.md
- [x] Create docs/features.md
- [x] Update docs/authentication.md
- [x] Update docs/troubleshooting.md
- [x] Create docs/migration-v2.md
- [x] Create docs/strategy/ folder with:
  - [x] ALM_OVERVIEW.md
  - [x] BRANCHING_STRATEGY.md
  - [x] ENVIRONMENT_STRATEGY.md

### Phase 5: Testing & Validation

**Status: PLANNED**

- [ ] Test composite actions in isolation
- [ ] Test reusable workflows end-to-end
- [ ] Test with ppds-demo repository
- [ ] Validate version comparison logic
- [ ] Validate retry logic
- [ ] Validate noise filtering patterns
- [ ] Validate Solution Checker integration

### Phase 6: Release

**Status: PLANNED**

- [ ] Create v2.0.0-beta.1 release for testing
- [ ] Update ppds-demo to use beta
- [ ] Gather feedback and fix issues
- [ ] Create v2.0.0 release
- [ ] Update major version tag (v2)
- [ ] Announce release

## Feature Status

### Core Features

| Feature | GitHub Actions | Azure DevOps |
|---------|---------------|--------------|
| Solution export | Complete | Planned |
| Solution import | Complete | Planned |
| Solution build | Complete | Planned |
| Solution validation | Complete | Planned |
| Solution deployment | Complete | Planned |
| Plugin deployment | Complete | Complete (v1) |
| Plugin extraction | Complete | Complete (v1) |

### Advanced Features

| Feature | Status |
|---------|--------|
| Version comparison | Complete |
| Retry logic | Complete |
| Noise filtering | Complete |
| Solution Checker | Complete |
| Deployment settings | Complete |
| .NET build | Complete |
| Plugin assembly copy | Complete |
| Plugin package copy | Complete |

## Known Issues

### PAC CLI Linux Bug
- Issue: `--allowDelete` doesn't work on Linux
- Status: Workaround implemented in `export-solution` action
- Reference: https://github.com/microsoft/powerplatform-build-tools/issues/448

### Azure DevOps Templates
- Issue: v2 templates not yet available
- Status: Phase 3 planned
- Workaround: Use v1 templates or custom pipelines

## Migration Support

### For v1 Users

1. Review the [Migration Guide](./docs/migration-v2.md)
2. Update workflow references to `@v2`
3. Update input parameters per migration guide
4. Test in non-production first

### Breaking Changes Summary

- Workflow paths changed (removed `.github` prefix for reusable workflows)
- Some input parameters renamed
- Credentials now use GitHub Environment variables
- Version comparison enabled by default (can be disabled)

## File Structure After Migration

```
ppds-alm/
├── .github/
│   ├── actions/                             # Composite actions
│   │   ├── setup-pac-cli/action.yml         # COMPLETE
│   │   ├── pac-auth/action.yml              # COMPLETE
│   │   ├── export-solution/action.yml       # COMPLETE
│   │   ├── import-solution/action.yml       # COMPLETE
│   │   ├── pack-solution/action.yml         # COMPLETE
│   │   ├── build-solution/action.yml        # COMPLETE
│   │   ├── check-solution/action.yml        # COMPLETE
│   │   ├── analyze-changes/action.yml       # COMPLETE
│   │   ├── copy-plugin-assemblies/action.yml # COMPLETE
│   │   └── copy-plugin-packages/action.yml  # COMPLETE
│   └── workflows/
│       └── ci.yml                           # Self-validation
├── github/
│   └── workflows/                           # Reusable workflows
│       ├── solution-export.yml              # COMPLETE
│       ├── solution-import.yml              # COMPLETE
│       ├── solution-build.yml               # COMPLETE
│       ├── solution-validate.yml            # COMPLETE
│       ├── solution-deploy.yml              # COMPLETE
│       ├── plugin-deploy.yml                # COMPLETE
│       ├── plugin-extract.yml               # COMPLETE
│       └── full-alm.yml                     # COMPLETE
├── azure-devops/
│   ├── templates/                           # PLANNED
│   └── examples/                            # PLANNED
├── docs/
│   ├── github-quickstart.md                 # COMPLETE
│   ├── azure-devops-quickstart.md           # COMPLETE
│   ├── authentication.md                    # COMPLETE
│   ├── actions-reference.md                 # COMPLETE
│   ├── features.md                          # COMPLETE
│   ├── troubleshooting.md                   # COMPLETE
│   ├── migration-v2.md                      # COMPLETE
│   └── strategy/
│       ├── ALM_OVERVIEW.md                  # COMPLETE
│       ├── BRANCHING_STRATEGY.md            # COMPLETE
│       └── ENVIRONMENT_STRATEGY.md          # COMPLETE
├── CHANGELOG.md                             # COMPLETE
├── README.md                                # COMPLETE
└── MIGRATION-CHECKLIST.md                   # This file
```

## Timeline

| Milestone | Status |
|-----------|--------|
| Phase 1: Composite Actions | Complete |
| Phase 2: Reusable Workflows | Complete |
| Phase 3: Azure DevOps Templates | Planned |
| Phase 4: Documentation | Complete |
| Phase 5: Testing | Planned |
| Phase 6: Release | Planned |

## Resources

- [README](./README.md) - Project overview
- [CHANGELOG](./CHANGELOG.md) - Release notes
- [Migration Guide](./docs/migration-v2.md) - Upgrade instructions
- [Actions Reference](./docs/actions-reference.md) - Action documentation
- [Features Guide](./docs/features.md) - Feature deep-dives

# Migration Checklist: Absorb Demo ALM into ppds-alm

**Branch:** `feature/absorb-demo-alm`
**Source:** `ppds-demo/.github/`
**Target:** `ppds-alm/`

---

## Executive Summary

This migration absorbs the proven ALM implementation from ppds-demo into ppds-alm, transforming it from a reference implementation into reusable templates. The demo implementation is significantly more mature than the current ALM templates, featuring:

- **Composite Actions**: 10 modular, reusable actions
- **Advanced Workflows**: 8 production-ready workflows
- **Enterprise Features**: Version comparison, retry logic, deployment settings, noise filtering, Solution Checker integration

---

## Inventory

### Demo Composite Actions (10 actions)

| Action | Purpose | Dependencies | Lines |
|--------|---------|--------------|-------|
| `setup-pac-cli` | Install .NET SDK and PAC CLI | .NET SDK, actions/setup-dotnet | 69 |
| `pac-auth` | Authenticate to Power Platform environment | PAC CLI | 82 |
| `export-solution` | Export and unpack solution (Both managed/unmanaged) | PAC CLI | 148 |
| `import-solution` | Import with version check, retry, settings support | PAC CLI, unzip, jq | 437 |
| `pack-solution` | Pack solution from unpacked source | PAC CLI | 71 |
| `build-solution` | Build .NET solution, locate outputs, run tests | .NET SDK | 256 |
| `check-solution` | Run PowerApps Solution Checker | PAC CLI, jq | 303 |
| `analyze-changes` | Filter noise from solution exports | Git, bash | 276 |
| `copy-plugin-assemblies` | Copy classic plugin DLLs to solution folder | bash | 152 |
| `copy-plugin-packages` | Copy plugin packages (.nupkg) to solution folder | bash | 163 |

### Demo Workflows (8 workflows)

| Workflow | Type | Purpose | Reusable? |
|----------|------|---------|-----------|
| `ci-build.yml` | Direct | Build solution, create artifacts | Template candidate |
| `ci-export.yml` | Direct | Export from Dev with noise filtering | Template candidate |
| `ci-plugin-deploy.yml` | Direct | Deploy plugins to Dev | Demo-specific |
| `pr-validate.yml` | Direct | Validate PRs (build, pack, checker) | Template candidate |
| `_deploy-solution.yml` | Reusable | Deploy solution to any environment | **Already reusable** |
| `cd-qa.yml` | Direct | Deploy to QA using artifacts | Demo-specific |
| `cd-prod.yml` | Direct | Deploy to Production, create release tags | Demo-specific |
| `codeql.yml` | Direct | Security scanning | Demo-specific |

### Current ALM Templates (to be replaced)

| GitHub Workflow | Azure DevOps Template | Status |
|-----------------|----------------------|--------|
| `plugin-deploy.yml` | `plugin-deploy.yml` | Replace |
| `plugin-extract.yml` | `plugin-extract.yml` | Replace |
| `solution-export.yml` | `solution-export.yml` | Replace |
| `solution-import.yml` | `solution-import.yml` | Replace |
| `full-alm.yml` | `full-alm.yml` | Replace |

---

## Breaking Changes

### Critical Breaking Changes

1. **Architecture Change**: Current templates use PPDS.Tools PowerShell module for plugin operations. New implementation uses PAC CLI for auth/export/import and custom scripts for plugin deployment.

2. **Input Parameter Renaming**:
   - `environment-url` (new) vs `environmentUrl` (current GitHub) vs parameter naming (ADO)
   - `client-id/client-secret/tenant-id` vs current naming conventions
   - Deployment settings file path conventions changed

3. **Feature Additions** (backward-compatible but behavior changes):
   - Version comparison now skips imports if target has same/newer version
   - Retry logic for transient failures (may delay failures)
   - Noise filtering on exports (may result in "no changes" where before there were changes)

4. **Removed Features**:
   - PPDS.Tools-based plugin drift detection (replaced with different approach)
   - Plugin registration extraction from assemblies (PPDS.Tools dependency)

### Impact Assessment

| Consumer Type | Impact | Migration Effort |
|--------------|--------|------------------|
| New consumers | None | N/A |
| ppds-demo | High | Update to use ALM templates |
| External consumers | High | Update workflow calls, secrets, inputs |

---

## Migration Checklist

### Phase 1: Create Composite Actions

- [x] **1.1** Create `.github/actions/` directory structure
- [x] **1.2** Migrate `setup-pac-cli` action
  - [x] Copy action.yml
  - [x] Update paths/references
  - [ ] Test in isolation
- [x] **1.3** Migrate `pac-auth` action
  - [x] Copy action.yml
  - [x] Update paths/references
  - [ ] Test in isolation
- [x] **1.4** Migrate `export-solution` action
  - [x] Copy action.yml
  - [x] Verify PAC CLI --allowDelete workaround documented
  - [ ] Test in isolation
- [x] **1.5** Migrate `import-solution` action
  - [x] Copy action.yml
  - [x] Verify retry logic
  - [x] Verify version comparison
  - [ ] Test in isolation
- [x] **1.6** Migrate `pack-solution` action
  - [x] Copy action.yml
  - [ ] Test in isolation
- [x] **1.7** Migrate `build-solution` action
  - [x] Copy action.yml
  - [x] Make solution-path configurable (remove PPDSDemo default)
  - [ ] Test in isolation
- [x] **1.8** Migrate `check-solution` action
  - [x] Copy action.yml
  - [x] Verify SARIF parsing
  - [ ] Test in isolation
- [x] **1.9** Migrate `analyze-changes` action
  - [x] Copy action.yml
  - [x] Document noise patterns
  - [ ] Test in isolation
- [x] **1.10** Migrate `copy-plugin-assemblies` action
  - [x] Copy action.yml
  - [x] Make naming convention configurable
  - [ ] Test in isolation
- [x] **1.11** Migrate `copy-plugin-packages` action
  - [x] Copy action.yml
  - [x] Make naming convention configurable
  - [ ] Test in isolation

### Phase 2: Create/Update Reusable Workflows

- [x] **2.1** ~~Create `_setup-environment.yml` (new)
  - Kept setup-pac-cli and pac-auth separate for flexibility-pac-cli and pac-auth
  - Workflows chain them directly without a wrapper/secrets
- [x] **2.2** Update `solution-export.yml`
  - [x] Use new export-solution action
  - [x] Add noise filtering option
  - [x] Add version stamping option
  - [x] Use secrets-based authentication-compatible inputs where possible
- [x] **2.3** Update `solution-import.yml`
  - [x] Use new import-solution action
  - [x] Add version comparison option
  - [x] Add retry configuration
  - [x] Add deployment settings support
- [x] **2.4** Create `solution-build.yml` (new)
  - [x] Use build-solution action
  - [x] Use copy-plugin-* actions
  - [x] Use pack-solution action
  - [x] Output artifact
- [x] **2.5** Create `solution-validate.yml` (new)
  - [x] Build and pack validation
  - [x] Solution Checker integration
  - [x] PR validation use case
- [x] **2.6** Create `solution-deploy.yml` (new)
  - [x] Based on _deploy-solution.yml from demo
  - [x] Secrets-based authentication deployment
  - [x] Optional plugin build
  - [x] Deployment settings auto-detection
- [x] **2.7** Update `plugin-deploy.yml`
  - [x] Decision made: Keep PPDS.Tools or migrate to PAC CLI
  - [x] Update inputs for consistency
- [x] **2.8** Update `plugin-extract.yml`
  - [x] Decision made: Keep PPDS.Tools or migrate
  - [x] Update inputs for consistency
- [x] **2.9** Update `full-alm.yml`
  - [x] Use composite actions to orchestrate new workflows
  - [x] Add build step
  - [x] Add PPDS plugin deployment step

### Phase 3: Update Azure DevOps Templates

- [ ] **3.1** Create `azure-devops/actions/` equivalent structure (if applicable)
- [ ] **3.2** Update `solution-export.yml`
  - [ ] Mirror GitHub workflow features
  - [ ] Use Power Platform Build Tools where appropriate
- [ ] **3.3** Update `solution-import.yml`
  - [ ] Add version comparison
  - [ ] Add retry logic
  - [ ] Add deployment settings
- [ ] **3.4** Create `solution-build.yml`
  - [ ] .NET build step
  - [ ] Plugin copy steps
  - [ ] Pack solution step
- [ ] **3.5** Create `solution-validate.yml`
  - [ ] PR validation template
  - [ ] Solution Checker integration
- [ ] **3.6** Create `solution-deploy.yml`
  - [ ] Environment-based deployment
  - [ ] Deployment settings support
- [ ] **3.7** Update `plugin-deploy.yml`
  - [ ] Consistency with GitHub version
- [ ] **3.8** Update `plugin-extract.yml`
  - [ ] Consistency with GitHub version
- [ ] **3.9** Update `full-alm.yml`
  - [ ] Orchestrate updated templates

### Phase 4: Documentation

- [ ] **4.1** Update `docs/github-quickstart.md`
  - [ ] New action usage examples
  - [ ] New workflow usage examples
  - [ ] Migration guide section
- [ ] **4.2** Update `docs/azure-devops-quickstart.md`
  - [ ] Updated template usage
  - [ ] Migration guide section
- [ ] **4.3** Update `docs/authentication.md`
  - [ ] GitHub Environment setup
  - [ ] Service principal requirements
  - [ ] Variable/secret naming conventions
- [ ] **4.4** Update `docs/troubleshooting.md`
  - [ ] PAC CLI --allowDelete Linux bug
  - [ ] Version comparison edge cases
  - [ ] Retry behavior explanation
- [ ] **4.5** Create `docs/migration-v1-to-v2.md`
  - [ ] Breaking changes detailed
  - [ ] Step-by-step migration guide
  - [ ] Input mapping table
- [ ] **4.6** Create `docs/actions/` folder
  - [ ] README for each action
  - [ ] Input/output documentation
  - [ ] Example usage
- [ ] **4.7** Update `CHANGELOG.md`
  - [ ] Document all changes
  - [ ] Breaking changes highlighted

### Phase 5: Examples

- [ ] **5.1** Update `azure-devops/examples/starter-pipeline.yml`
  - [ ] Use new templates
  - [ ] Minimal configuration example
- [ ] **5.2** Update `azure-devops/examples/advanced-pipeline.yml`
  - [ ] Full feature example
  - [ ] Multi-environment deployment
- [ ] **5.3** Create `github/examples/` folder
  - [ ] `starter-workflow.yml` - Minimal example
  - [ ] `advanced-workflow.yml` - Full features
  - [ ] `multi-environment.yml` - Dev/QA/Prod pipeline

### Phase 6: Update ppds-demo

- [ ] **6.1** Update demo to consume ppds-alm actions
  - [ ] Remove local `.github/actions/` folder
  - [ ] Reference `joshsmithxrm/ppds-alm/.github/actions/*`
- [ ] **6.2** Update demo workflows
  - [ ] Use ppds-alm reusable workflows where applicable
  - [ ] Keep demo-specific workflows (cd-qa, cd-prod, etc.)
- [ ] **6.3** Test full ALM flow
  - [ ] CI: Export from Dev
  - [ ] CI: Build
  - [ ] PR: Validate
  - [ ] CD: Deploy to QA
  - [ ] CD: Deploy to Prod

### Phase 7: Verification

- [ ] **7.1** Run actionlint on all GitHub workflows
- [ ] **7.2** YAML syntax validation (all files)
- [ ] **7.3** Create test branch in ppds-demo
  - [ ] Reference ppds-alm feature branch
  - [ ] Run export workflow
  - [ ] Run build workflow
  - [ ] Run validate workflow
  - [ ] Run deploy workflow
- [ ] **7.4** Document any issues found
- [ ] **7.5** Fix issues and re-test

### Phase 8: Release

- [ ] **8.1** Update CHANGELOG.md with final changes
- [ ] **8.2** Merge feature branch to main
- [ ] **8.3** Create release tag `v2.0.0`
- [ ] **8.4** Update `v2` tag alias
- [ ] **8.5** Create GitHub Release with notes
- [ ] **8.6** Update ppds-demo to use released version
- [ ] **8.7** Announce breaking changes (if external consumers exist)

---

## File Structure After Migration

```
ppds-alm/
├── .github/
│   ├── actions/                             # Composite actions (uses: .github/actions/*)
│   │   ├── setup-pac-cli/
│   │   │   └── action.yml                   # DONE
│   │   ├── pac-auth/
│   │   │   └── action.yml                   # DONE
│   │   ├── export-solution/
│   │   │   └── action.yml                   # DONE
│   │   ├── import-solution/
│   │   │   └── action.yml                   # DONE
│   │   ├── pack-solution/
│   │   │   └── action.yml                   # DONE
│   │   ├── build-solution/
│   │   │   └── action.yml                   # DONE
│   │   ├── check-solution/
│   │   │   └── action.yml                   # DONE
│   │   ├── analyze-changes/
│   │   │   └── action.yml                   # DONE
│   │   ├── copy-plugin-assemblies/
│   │   │   └── action.yml                   # DONE
│   │   └── copy-plugin-packages/
│   │       └── action.yml                   # DONE
│   └── workflows/
│       └── ci.yml                           # Self-validation
├── github/
│   ├── workflows/                           # Reusable workflows (workflow_call)
│   │   ├── _setup-environment.yml          # NEW: Setup + auth
│   │   ├── solution-export.yml             # UPDATED
│   │   ├── solution-import.yml             # UPDATED
│   │   ├── solution-build.yml              # NEW
│   │   ├── solution-validate.yml           # NEW
│   │   ├── solution-deploy.yml             # NEW
│   │   ├── plugin-deploy.yml               # UPDATED
│   │   ├── plugin-extract.yml              # UPDATED
│   │   └── full-alm.yml                    # UPDATED
│   └── examples/
│       ├── starter-workflow.yml            # NEW
│       ├── advanced-workflow.yml           # NEW
│       └── multi-environment.yml           # NEW
├── azure-devops/
│   ├── templates/
│   │   ├── solution-export.yml             # UPDATED
│   │   ├── solution-import.yml             # UPDATED
│   │   ├── solution-build.yml              # NEW
│   │   ├── solution-validate.yml           # NEW
│   │   ├── solution-deploy.yml             # NEW
│   │   ├── plugin-deploy.yml               # UPDATED
│   │   ├── plugin-extract.yml              # UPDATED
│   │   └── full-alm.yml                    # UPDATED
│   └── examples/
│       ├── starter-pipeline.yml            # UPDATED
│       └── advanced-pipeline.yml           # UPDATED
├── docs/
│   ├── github-quickstart.md                # UPDATED
│   ├── azure-devops-quickstart.md          # UPDATED
│   ├── authentication.md                   # UPDATED
│   ├── troubleshooting.md                  # UPDATED
│   ├── migration-v1-to-v2.md               # NEW
│   └── actions/
│       └── README.md                       # NEW
├── CHANGELOG.md                            # UPDATED
├── CLAUDE.md
├── MIGRATION-CHECKLIST.md                  # THIS FILE (delete after migration)
└── README.md
```

---

## Notes

### Key Decisions Needed

1. **PPDS.Tools Dependency**: Keep for plugin registration extraction, or remove entirely?
   - Current: Used for `Get-DataversePluginRegistrations` and `Deploy-DataversePlugins`
   - Demo: Uses custom PowerShell scripts in `tools/` folder
   - Recommendation: Keep PPDS.Tools for plugin operations, use PAC CLI for solution operations

2. **Versioning Strategy**: This is a breaking change release
   - Recommendation: Release as v2.0.0 with v1.x maintained on separate branch

3. **Action vs Workflow**: Some actions could be workflows
   - Recommendation: Keep granular actions, compose into workflows for common patterns

### Testing Strategy

Since CI/CD templates can't be unit tested, manual verification is required:
1. Create test branch in ppds-demo
2. Reference ppds-alm feature branch
3. Run each workflow type
4. Verify expected behavior
5. Document results

### Rollback Plan

If migration fails:
1. Keep v1.x branch with current implementation
2. Consumers can pin to v1.x
3. Fix issues in v2.x branch
4. Re-attempt migration

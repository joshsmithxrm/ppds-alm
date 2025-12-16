# CLAUDE.md - ppds-alm

**CI/CD templates for Power Platform ALM automation.**

---

## Project Overview

This repository contains reusable CI/CD templates for GitHub Actions and Azure DevOps, enabling automated plugin deployment and solution management.

**Part of the PPDS Ecosystem** - See `C:\VS\ppds\CLAUDE.md` for cross-project context.

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| GitHub Actions | Reusable workflows |
| Azure DevOps | Pipeline templates |
| YAML | Template definitions |
| PowerShell | Runtime (via PPDS.Tools) |

---

## Project Structure

```
ppds-alm/
├── .github/
│   └── workflows/
│       └── ci.yml                    # Self-validation
├── github/
│   └── workflows/                    # Reusable workflows for CONSUMERS
│       ├── plugin-deploy.yml
│       ├── plugin-extract.yml
│       ├── solution-export.yml
│       ├── solution-import.yml
│       └── full-alm.yml
├── azure-devops/
│   ├── templates/                    # Templates for CONSUMERS
│   │   ├── plugin-deploy.yml
│   │   ├── plugin-extract.yml
│   │   ├── solution-export.yml
│   │   ├── solution-import.yml
│   │   └── full-alm.yml
│   └── examples/
│       ├── starter-pipeline.yml
│       └── advanced-pipeline.yml
├── docs/
│   ├── github-quickstart.md
│   ├── azure-devops-quickstart.md
│   ├── authentication.md
│   └── troubleshooting.md
└── CHANGELOG.md
```

---

## Template Types

### GitHub Actions (Reusable Workflows)

Located in `github/workflows/` - consumers call with `uses:`

```yaml
# Consumer usage
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1
    with:
      environment-url: 'https://myorg.crm.dynamics.com'
    secrets:
      client-id: ${{ secrets.CLIENT_ID }}
      client-secret: ${{ secrets.CLIENT_SECRET }}
      tenant-id: ${{ secrets.TENANT_ID }}
```

### Azure DevOps (Pipeline Templates)

Located in `azure-devops/templates/` - consumers reference via repository resource

```yaml
# Consumer usage
resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      ref: refs/tags/v1.0.0

stages:
  - template: azure-devops/templates/plugin-deploy.yml@ppds-alm
    parameters:
      environmentUrl: 'https://myorg.crm.dynamics.com'
```

---

## Available Templates

| Template | Purpose |
|----------|---------|
| `plugin-extract.yml` | Extract registrations from compiled assembly |
| `plugin-deploy.yml` | Deploy plugins with drift detection |
| `solution-export.yml` | Export solution from environment |
| `solution-import.yml` | Import solution to environment |
| `full-alm.yml` | Complete build-deploy pipeline |

---

## Development Workflow

### Modifying Templates

1. Create feature branch from `main`
2. Edit templates in `github/workflows/` or `azure-devops/templates/`
3. Test changes (see Testing section)
4. Update `CHANGELOG.md`
5. Create PR to `main`

### Testing Templates

**GitHub Actions:**
- Create test repo that references your branch
- Or use workflow_dispatch for manual testing

**Azure DevOps:**
- Test with actual Azure DevOps pipeline
- Use branch ref in repository resource

---

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Protected, always releasable |
| `feature/*` | New features |
| `fix/*` | Bug fixes |

**Merge Strategy:** Squash merge to main

---

## Release / Versioning

This repo uses **git tags** for versioning. No package publishing.

### Tag Strategy

| Tag | Purpose |
|-----|---------|
| `v1.0.0` | Specific version (recommended for production) |
| `v1` | Major version alias (auto-updated, convenience) |

### Release Process

1. Update `CHANGELOG.md`
2. Merge to `main`
3. Create tag: `git tag v1.0.0 && git push origin v1.0.0`
4. Create GitHub Release from tag
5. Update major version tag: `git tag -fa v1 -m "Update v1 to v1.0.0" && git push origin v1 --force`

### Consumer Version References

```yaml
# Specific version (stable)
uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1.0.0

# Major version (gets updates)
uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1

# Main branch (bleeding edge - not recommended)
uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@main
```

---

## Template Design Patterns

### Input/Secret Separation
```yaml
on:
  workflow_call:
    inputs:
      environment-url:           # Non-sensitive config
        required: true
        type: string
    secrets:
      client-id:                 # Sensitive credentials
        required: true
```

### Fail-Fast with Clear Errors
```yaml
- name: Validate inputs
  shell: pwsh
  run: |
    if (-not '${{ inputs.environment-url }}') {
      Write-Error "environment-url is required"
      exit 1
    }
```

### Consistent PowerShell Usage
```yaml
- name: Deploy
  shell: pwsh  # Always use pwsh, not powershell
  run: |
    Import-Module PPDS.Tools
    # ...
```

---

## Ecosystem Integration

**Depends on:**
- `PPDS.Tools` PowerShell module (installed from PSGallery in workflows)

**Used by:**
- **ppds-demo** - Reference pipelines
- **Customer projects** - Production ALM

---

## Key Files

| File | Purpose |
|------|---------|
| `github/workflows/*.yml` | GitHub reusable workflows |
| `azure-devops/templates/*.yml` | ADO pipeline templates |
| `docs/` | Consumer documentation |
| `CHANGELOG.md` | Release notes |

---

## Documentation

Maintain docs in `docs/` for consumers:
- **github-quickstart.md** - GitHub Actions setup
- **azure-devops-quickstart.md** - Azure DevOps setup
- **authentication.md** - Credential setup guide
- **troubleshooting.md** - Common issues

---

## Testing Requirements

CI/CD templates cannot be unit tested - they must be run in actual CI/CD environments.

**Before PR:**
1. **YAML linting:** Run `actionlint` on GitHub Actions workflows
2. **Syntax validation:** Ensure YAML parses correctly
3. **Manual verification:** Create a test branch in `ppds-demo` that references your ALM branch, run the workflow, verify it works

```bash
# Install actionlint (one-time)
# https://github.com/rhysd/actionlint

# Lint GitHub Actions workflows
actionlint github/workflows/*.yml
```

---

## Decision Presentation

When presenting choices or asking questions:
1. **Lead with your recommendation** and rationale
2. **List alternatives considered** and why they're not preferred
3. **Ask for confirmation**, not open-ended input

❌ "What testing approach should we use?"
✅ "I recommend X because Y. Alternatives considered: A (rejected because B), C (rejected because D). Do you agree?"

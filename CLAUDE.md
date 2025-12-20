# CLAUDE.md - ppds-alm

**CI/CD templates for Power Platform ALM automation.**

**Part of the PPDS Ecosystem** - See `C:\VS\ppds\CLAUDE.md` for cross-project context.

---

## 🚫 NEVER

| Rule | Why |
|------|-----|
| Use `powershell` shell in workflows | Use `pwsh` for PowerShell 7+ |
| Hardcode secrets in templates | Use `secrets:` inputs for credentials |
| Skip input validation | Fail fast with clear error messages |
| Use `@main` in production | Pin to specific version tags (`@v1.0.0`) |
| Modify consumer-facing templates without testing | Changes affect all consumers |
| Force push version tags | Breaks consumers pinned to that version |

---

## ✅ ALWAYS

| Rule | Why |
|------|-----|
| Use `pwsh` shell for PowerShell | Ensures PowerShell 7+ cross-platform |
| Separate inputs from secrets | Clear security boundary |
| Validate inputs early | Fail fast with helpful errors |
| Use version tags for releases | Consumers need stable references |
| Test templates before merge | CI/CD failures are costly for consumers |
| Document required secrets | Consumers need setup instructions |

---

## 💻 Tech Stack

| Technology | Purpose |
|------------|---------|
| GitHub Actions | Reusable workflows |
| Azure DevOps | Pipeline templates |
| YAML | Template definitions |
| PowerShell | Runtime (via PPDS.Tools) |

---

## 📁 Project Structure

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
│   ├── GITHUB_QUICKSTART.md
│   ├── AZURE_DEVOPS_QUICKSTART.md
│   ├── AUTHENTICATION.md
│   ├── ACTIONS_REFERENCE.md
│   ├── FEATURES.md
│   ├── MIGRATION_V2.md
│   ├── TROUBLESHOOTING.md
│   └── strategy/
└── CHANGELOG.md
```

---

## 🛠️ Common Commands

```bash
# Lint GitHub Actions workflows
actionlint github/workflows/*.yml

# Validate YAML syntax
yamllint github/workflows/*.yml azure-devops/templates/*.yml
```

---

## 📋 Available Templates

| Template | Purpose |
|----------|---------|
| `plugin-extract.yml` | Extract registrations from compiled assembly |
| `plugin-deploy.yml` | Deploy plugins with drift detection |
| `solution-export.yml` | Export solution from environment |
| `solution-import.yml` | Import solution to environment |
| `full-alm.yml` | Complete build-deploy pipeline |

---

## 🔄 Template Design Patterns

### Input/Secret Separation

```yaml
# ✅ Correct - Clear separation of inputs and secrets
on:
  workflow_call:
    inputs:
      environment-url:           # Non-sensitive config
        required: true
        type: string
    secrets:
      client-id:                 # Sensitive credentials
        required: true

# ❌ Wrong - Secrets as inputs
on:
  workflow_call:
    inputs:
      client-secret:             # Security risk!
        required: true
        type: string
```

### Fail-Fast with Clear Errors

```yaml
# ✅ Correct - Validate early with helpful message
- name: Validate inputs
  shell: pwsh
  run: |
    if (-not '${{ inputs.environment-url }}') {
      Write-Error "environment-url is required"
      exit 1
    }

# ❌ Wrong - Let it fail later with cryptic error
- name: Deploy
  run: pac auth create --url ${{ inputs.environment-url }}
```

### Consistent PowerShell Usage

```yaml
# ✅ Correct - Use pwsh for PowerShell 7+
- name: Deploy
  shell: pwsh
  run: |
    Import-Module PPDS.Tools
    # ...

# ❌ Wrong - Uses Windows PowerShell 5.1
- name: Deploy
  shell: powershell
  run: |
    Import-Module PPDS.Tools
```

---

## 📦 Consumer Usage

### GitHub Actions

```yaml
# Consumer usage
jobs:
  deploy:
    uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1.0.0
    with:
      environment-url: 'https://myorg.crm.dynamics.com'
    secrets:
      client-id: ${{ secrets.CLIENT_ID }}
      client-secret: ${{ secrets.CLIENT_SECRET }}
      tenant-id: ${{ secrets.TENANT_ID }}
```

### Azure DevOps

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

## 🔀 Git Branch & Merge Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Protected, always releasable |
| `feature/*` | New features |
| `fix/*` | Bug fixes |

**Merge Strategy:** Squash merge to main

---

## 🏷️ Version / Tag Strategy

This repo uses **git tags** for versioning. No package publishing.

| Tag | Purpose |
|-----|---------|
| `v1.0.0` | Specific version (recommended for production) |
| `v1` | Major version alias (auto-updated, convenience) |

### Consumer Version References

```yaml
# ✅ Specific version (stable, recommended)
uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1.0.0

# ⚠️ Major version (gets updates, use with caution)
uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@v1

# ❌ Main branch (bleeding edge - not recommended)
uses: joshsmithxrm/ppds-alm/.github/workflows/plugin-deploy.yml@main
```

---

## 🚀 Release Process

1. Update `CHANGELOG.md`
2. Merge to `main`
3. Create tag: `git tag v1.0.0 && git push origin v1.0.0`
4. Create GitHub Release from tag
5. Update major version tag: `git tag -fa v1 -m "Update v1 to v1.0.0" && git push origin v1 --force`

---

## 🧪 Testing Requirements

CI/CD templates cannot be unit tested - they must be run in actual CI/CD environments.

**Before PR:**
1. **YAML linting:** Run `actionlint` on GitHub Actions workflows
2. **Syntax validation:** Ensure YAML parses correctly
3. **Manual verification:** Create a test branch in `ppds-demo` that references your ALM branch, run the workflow, verify it works

---

## 🔗 Dependencies & Versioning

### This Repo Produces

| Output | Distribution |
|--------|--------------|
| GitHub Actions workflows | Git tags |
| Azure DevOps templates | Git tags |

### Dependencies

| Dependency | Minimum | Used By |
|------------|---------|---------|
| PPDS.Tools | 1.1.0 | `plugin-deploy.yml`, `plugin-extract.yml` |
| PAC CLI | 1.32.0 | Solution workflows |

### Consumed By

| Consumer | How | Breaking Change Impact |
|----------|-----|------------------------|
| ppds-demo | References workflows | Must update workflow refs |
| Customer projects | References workflows | Must update workflow refs |

### Version Sync Rules

| Rule | Details |
|------|---------|
| Major versions | Sync with ppds-tools when using new cmdlet features |
| Minor/patch | Independent |
| Pre-release format | `-beta.N` suffix in git tag; do NOT update `v1` alias for pre-releases |

### Breaking Changes Requiring Coordination

- Changing required workflow inputs
- Changing secret names
- Updating to new PPDS.Tools major version

### Pinning Dependencies

```yaml
# In plugin workflows, pin to minimum compatible Tools version:
Install-Module PPDS.Tools -MinimumVersion '1.1.0' -Force
```

---

## 📚 Documentation

Maintain docs in `docs/` for consumers:
- **GITHUB_QUICKSTART.md** - GitHub Actions setup
- **AZURE_DEVOPS_QUICKSTART.md** - Azure DevOps setup
- **AUTHENTICATION.md** - Credential setup guide
- **ACTIONS_REFERENCE.md** - Detailed action documentation
- **FEATURES.md** - Advanced features guide
- **TROUBLESHOOTING.md** - Common issues

---

## 📋 Key Files

| File | Purpose |
|------|---------|
| `github/workflows/*.yml` | GitHub reusable workflows |
| `azure-devops/templates/*.yml` | ADO pipeline templates |
| `docs/` | Consumer documentation |
| `CHANGELOG.md` | Release notes |

---

## ⚖️ Decision Presentation

When presenting choices or asking questions:
1. **Lead with your recommendation** and rationale
2. **List alternatives considered** and why they're not preferred
3. **Ask for confirmation**, not open-ended input

❌ "What testing approach should we use?"
✅ "I recommend X because Y. Alternatives considered: A (rejected because B), C (rejected because D). Do you agree?"

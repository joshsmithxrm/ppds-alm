# CLAUDE.md - ppds-alm

**CI/CD templates for Power Platform ALM automation.**

**Part of the PPDS Ecosystem** - See `C:\VS\ppds\CLAUDE.md` for cross-project context.

**Consumption guidance:** See [CONSUMPTION_PATTERNS.md](../docs/CONSUMPTION_PATTERNS.md) for when consumers should use library vs CLI vs Tools.

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
| GitHub Actions | Reusable workflows and composite actions |
| YAML | Template definitions |
| Bash | Runtime scripts |
| PowerShell | Cross-platform scripts (pwsh) |

---

## 📁 Project Structure

```
ppds-alm/
├── .github/
│   ├── actions/                      # Composite actions for CONSUMERS
│   │   ├── setup-pac-cli/
│   │   ├── pac-auth/
│   │   ├── export-solution/
│   │   ├── import-solution/
│   │   └── ...
│   └── workflows/                    # All workflows
│       ├── _ci.yml                   # Internal (self-validation)
│       ├── solution-deploy.yml       # Reusable workflows for CONSUMERS
│       ├── solution-export.yml
│       ├── solution-import.yml
│       ├── solution-build.yml
│       ├── solution-validate.yml
│       ├── plugin-deploy.yml
│       ├── plugin-extract.yml
│       ├── solution-promote.yml
│       └── azure-deploy.yml
├── bicep/                            # Azure Bicep modules
├── docs/
│   ├── GITHUB_QUICKSTART.md
│   ├── AUTHENTICATION.md
│   ├── ACTIONS_REFERENCE.md
│   ├── FEATURES.md
│   ├── AZURE_INTEGRATION.md
│   ├── AZURE_OIDC_SETUP.md
│   ├── TROUBLESHOOTING.md
│   └── strategy/
└── CHANGELOG.md
```

---

## 🛠️ Common Commands

```bash
# Lint GitHub Actions workflows
actionlint .github/workflows/*.yml

# Validate YAML syntax
yamllint .github/workflows/*.yml
```

---

## 📋 Available Templates

| Template | Purpose |
|----------|---------|
| `plugin-extract.yml` | Extract registrations from compiled assembly |
| `plugin-deploy.yml` | Deploy plugins with drift detection |
| `solution-export.yml` | Export solution from environment |
| `solution-import.yml` | Import solution to environment |
| `solution-promote.yml` | Promote solution between environments |
| `azure-deploy.yml` | Deploy Azure integration resources |

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

### Consistent Shell Usage

```yaml
# ✅ Correct - Use bash for cross-platform scripts
- name: Deploy
  shell: bash
  run: |
    ppds plugin deploy --registration-file "$REG_FILE" ...

# ✅ Also correct - Use pwsh when PowerShell is needed
- name: Setup
  shell: pwsh
  run: |
    # PowerShell-specific logic

# ❌ Wrong - Uses Windows PowerShell 5.1 (not cross-platform)
- name: Deploy
  shell: powershell
  run: |
    # This only works on Windows
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
      registration-file: ./registrations.json
    secrets:
      environment-url: ${{ secrets.ENVIRONMENT_URL }}
      client-id: ${{ secrets.CLIENT_ID }}
      client-secret: ${{ secrets.CLIENT_SECRET }}
      tenant-id: ${{ secrets.TENANT_ID }}
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
| Composite actions | Git tags |
| Azure Bicep modules | Git tags |

### Dependencies

| Dependency | Minimum | Used By |
|------------|---------|---------|
| PPDS.Cli | latest | `plugin-deploy.yml`, `plugin-extract.yml` |
| PAC CLI | latest | `solution-*.yml` workflows |

### Consumed By

| Consumer | How | Breaking Change Impact |
|----------|-----|------------------------|
| ppds-demo | References workflows | Must update workflow refs |
| Customer projects | References workflows | Must update workflow refs |

### Version Sync Rules

| Rule | Details |
|------|---------|
| Major versions | Sync with ppds-sdk when using new CLI features |
| Minor/patch | Independent |
| Pre-release format | `-beta.N` suffix in git tag; do NOT update `v1` alias for pre-releases |

### Breaking Changes Requiring Coordination

- Changing required workflow inputs
- Changing secret names
- Updating to new PPDS.Cli major version

### Pinning Dependencies

```yaml
# In plugin workflows, pin to a specific CLI version:
dotnet tool install --global PPDS.Cli --version "1.0.0"
```

---

## 📚 Documentation

Maintain docs in `docs/` for consumers:
- **GITHUB_QUICKSTART.md** - GitHub Actions setup
- **AUTHENTICATION.md** - Power Platform credential setup
- **WORKFLOWS_REFERENCE.md** - All workflows documented
- **ACTIONS_REFERENCE.md** - All actions documented
- **CONSUMPTION_GUIDE.md** - Actions vs workflows guidance
- **FEATURES.md** - Advanced features guide
- **AZURE_INTEGRATION.md** - Bicep modules and naming
- **AZURE_OIDC_SETUP.md** - Azure OIDC for GitHub Actions
- **AZURE_COORDINATION.md** - Azure and Dataverse coordination
- **TROUBLESHOOTING.md** - Common issues

---

## 📋 Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/*.yml` | GitHub reusable workflows |
| `.github/actions/*/action.yml` | Composite actions |
| `bicep/modules/*.bicep` | Azure Bicep modules |
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

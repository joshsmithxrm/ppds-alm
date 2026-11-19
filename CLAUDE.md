# PPDS ALM

CI/CD templates for Power Platform ALM automation.

## NEVER

- Use `powershell` shell in workflows - use `pwsh` for PowerShell 7+
- Hardcode secrets in templates - use `secrets:` inputs
- Use `@main` in production - pin to specific version tags (`@v1.0.0`)
- Force push version tags - breaks consumers pinned to that version
- Modify consumer-facing templates without testing

## ALWAYS

- Use `pwsh` shell for PowerShell - ensures PowerShell 7+ cross-platform
- Separate inputs from secrets - clear security boundary
- Validate inputs early - fail fast with helpful errors
- Use version tags for releases - consumers need stable references
- Document required secrets - consumers need setup instructions

## Available Templates

| Template | Purpose |
|----------|---------|
| `plugin-extract.yml` | Extract registrations from assembly |
| `plugin-deploy.yml` | Deploy plugins with drift detection |
| `solution-export.yml` | Export solution from environment |
| `solution-import.yml` | Import solution to environment |
| `solution-build.yml` | Build .NET code and pack solution |
| `solution-validate.yml` | PR validation: build, pack, optional Solution Checker |
| `solution-deploy.yml` | Build, pack, and import to target environment |
| `solution-promote.yml` | Promote between environments |
| `azure-deploy.yml` | Deploy Azure integration resources |

`_ci.yml` is this repo's own CI, not a reusable template.

## Commands

| Command | Purpose |
|---------|---------|
| `python3 -m pip install -r tests/requirements.txt` | Install offline test dependencies |
| `python3 -m unittest discover -s tests -v` | Offline contract tests (what CI runs; see `tests/README.md`) |

CI also parses every workflow and action file with `yaml.safe_load`. `actionlint` is not part of CI: it reports false positives on `job.workflow_*` (see `tests/README.md`).

## Version Strategy

| Tag | Purpose |
|-----|---------|
| `v1.0.0` | Specific version (recommended) |
| `v1` | Major version alias (latest v1.x release) |

## Key Files

- `.github/workflows/*.yml` - Reusable workflows
- `.github/actions/*/action.yml` - Composite actions
- `bicep/modules/*.bicep` - Azure Bicep modules
- `docs/` - Consumer documentation

## See Also

- `docs/GITHUB_QUICKSTART.md` - Setup guide
- `docs/AUTHENTICATION.md` - Credential setup
- `README.md#quick-start` - Consumer examples

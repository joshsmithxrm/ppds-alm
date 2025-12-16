# Actions Reference

Complete reference for all PPDS ALM composite actions.

## Overview

Composite actions are granular, reusable building blocks for Power Platform ALM workflows. Use them to build custom pipelines with precise control over each step.

## Setup Actions

### setup-pac-cli

Installs .NET SDK and Power Platform CLI.

**Usage:**
```yaml
- name: Setup PAC CLI
  uses: joshsmithxrm/ppds-alm/.github/actions/setup-pac-cli@v2
  with:
    pac-version: '1.35.5'  # Optional: pin specific version
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `dotnet-version` | No | `8.x` | .NET SDK version to install |
| `pac-version` | No | (latest) | PAC CLI version (empty = latest) |

**Outputs:**

| Output | Description |
|--------|-------------|
| `pac-version` | Installed PAC CLI version |

**Notes:**
- Pinning `pac-version` is recommended for production stability
- Find versions at: https://www.nuget.org/packages/Microsoft.PowerApps.CLI.Tool

---

### pac-auth

Authenticates to a Power Platform environment using service principal.

**Usage:**
```yaml
- name: Authenticate
  uses: joshsmithxrm/ppds-alm/.github/actions/pac-auth@v2
  with:
    environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
    tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
    client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
    client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment-url` | Yes | - | Power Platform environment URL |
| `tenant-id` | Yes | - | Azure AD tenant ID |
| `client-id` | Yes | - | Service principal application ID |
| `client-secret` | Yes | - | Service principal client secret |
| `name` | No | `default` | Auth profile name (for multiple connections) |

**Outputs:**

| Output | Description |
|--------|-------------|
| `environment-id` | Connected environment ID |
| `user-id` | Connected user/application ID |

**Prerequisites:**
- PAC CLI must be installed (use `setup-pac-cli` first)

---

## Solution Export/Import Actions

### export-solution

Exports and unpacks a Power Platform solution from the authenticated environment.

**Usage:**
```yaml
- name: Export solution
  uses: joshsmithxrm/ppds-alm/.github/actions/export-solution@v2
  with:
    solution-name: MySolution
    output-folder: solutions/MySolution/src
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-name` | Yes | - | Solution unique name to export |
| `output-folder` | Yes | - | Folder for unpacked solution |
| `temp-folder` | No | `./exports` | Temporary folder for zip files |

**Outputs:**

| Output | Description |
|--------|-------------|
| `solution-folder` | Path to unpacked solution folder |

**Behavior:**
- Exports **both** managed and unmanaged solutions
- Unpacks with `--packagetype Both` for a single source folder
- Includes workaround for PAC CLI `--allowDelete` bug on Linux
- Publishes customizations before export
- Validates unpack output

**Known Issue:**
PAC CLI's `--allowDelete` flag doesn't work correctly on Linux. This action deletes the solution folder before unpack to ensure removed components are properly deleted.

---

### import-solution

Imports a Power Platform solution with enterprise-grade features.

**Usage:**
```yaml
- name: Import solution
  id: import
  uses: joshsmithxrm/ppds-alm/.github/actions/import-solution@v2
  with:
    solution-path: ./exports/MySolution_managed.zip
    solution-name: MySolution
    skip-if-same-version: 'true'
    max-retries: '3'
    settings-file: ./config/qa.deploymentsettings.json

- name: Check result
  run: |
    echo "Imported: ${{ steps.import.outputs.imported }}"
    echo "Skipped: ${{ steps.import.outputs.skipped }}"
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-path` | Yes | - | Path to solution zip file |
| `solution-name` | No | - | Solution unique name (for version check) |
| `force-overwrite` | No | `true` | Force overwrite if solution exists |
| `publish-changes` | No | `true` | Publish customizations after import |
| `async` | No | `true` | Use async import (recommended for large solutions) |
| `cleanup` | No | `true` | Delete solution zip after import |
| `skip-if-same-version` | No | `true` | Skip if target has same or newer version |
| `max-retries` | No | `3` | Maximum retry attempts |
| `retry-delay-seconds` | No | `300` | Delay between retries (5 minutes) |
| `settings-file` | No | - | Path to deployment settings JSON |

**Outputs:**

| Output | Description |
|--------|-------------|
| `imported` | Whether solution was imported (`true`/`false`) |
| `skipped` | Whether import was skipped (version match) |
| `import-version` | Version of solution being imported |
| `target-version` | Version in target environment |
| `retry-count` | Number of retry attempts made |

**Version Comparison:**
When `skip-if-same-version` is `true` and `solution-name` is provided:
- Extracts version from solution zip
- Queries target environment for existing version
- Skips import if target version >= import version

**Retry Logic:**
- Only retries transient errors (concurrent import conflicts)
- Deterministic errors (missing dependencies, etc.) fail immediately
- Re-checks version before retry in case another process succeeded

---

### pack-solution

Packs a Power Platform solution from unpacked source files.

**Usage:**
```yaml
- name: Pack solution
  id: pack
  uses: joshsmithxrm/ppds-alm/.github/actions/pack-solution@v2
  with:
    solution-folder: solutions/MySolution/src
    solution-name: MySolution
    package-type: Managed

- name: Use packed solution
  run: echo "Packed to ${{ steps.pack.outputs.solution-path }}"
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-folder` | Yes | - | Path to unpacked solution folder |
| `solution-name` | Yes | - | Solution name (used in output filename) |
| `output-folder` | No | `./exports` | Output folder for packed zip |
| `package-type` | No | `Managed` | Managed, Unmanaged, or Both |

**Outputs:**

| Output | Description |
|--------|-------------|
| `solution-path` | Full path to packed solution zip file |

**Output Naming:**
- Managed: `{solution-name}_managed.zip`
- Unmanaged: `{solution-name}_unmanaged.zip`

---

## Build Actions

### build-solution

Builds the .NET solution containing plugins, workflow activities, and custom APIs.

**Usage:**
```yaml
- name: Build .NET solution
  id: build
  uses: joshsmithxrm/ppds-alm/.github/actions/build-solution@v2
  with:
    solution-path: MySolution.sln
    configuration: Release
    run-tests: 'true'

- name: Use outputs
  run: |
    echo "Classic DLL: ${{ steps.build.outputs.classic-assembly-path }}"
    echo "Plugin Package: ${{ steps.build.outputs.plugin-package-path }}"
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-path` | No | (auto-detect) | Path to .NET solution file |
| `configuration` | No | `Release` | Build configuration |
| `dotnet-version` | No | `8.x` | .NET SDK version |
| `run-tests` | No | `false` | Run unit tests after build |
| `test-filter` | No | - | Test filter expression |
| `plugins-folder` | No | `src/Plugins` | Folder containing plugin projects |
| `plugin-packages-folder` | No | `src/PluginPackages` | Folder containing plugin package projects |
| `shared-folder` | No | `src/Shared` | Folder containing shared projects |

**Outputs:**

| Output | Description |
|--------|-------------|
| `classic-assembly-path` | Path to classic plugin assembly DLL |
| `plugin-package-path` | Path to plugin package NuGet file |
| `entities-assembly-path` | Path to entities assembly DLL |
| `build-succeeded` | Whether build completed successfully |
| `test-succeeded` | Whether tests passed (empty if not run) |

**Auto-Detection:**
- If `solution-path` is empty, finds first `.sln` file in repository root
- Locates build outputs based on folder conventions

---

### copy-plugin-assemblies

Copies built plugin assemblies to the solution's PluginAssemblies folder.

**Usage:**
```yaml
- name: Copy plugin assemblies
  uses: joshsmithxrm/ppds-alm/.github/actions/copy-plugin-assemblies@v2
  with:
    source-assembly: src/Plugins/MyProject.Plugins/bin/Release/net462/MyProject.Plugins.dll
    solution-folder: solutions/MySolution/src
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `source-assembly` | Yes | - | Path to built plugin assembly DLL |
| `solution-folder` | Yes | - | Path to unpacked solution folder |

**Outputs:**

| Output | Description |
|--------|-------------|
| `copied-count` | Number of locations where assembly was copied |
| `target-path` | Path where assembly was copied |

**Naming Convention:**
- Build output: `MyProject.Plugins.dll`
- Solution expects: `MyProjectPlugins.dll` (dots removed)
- Target folder: `PluginAssemblies/MyProjectPlugins-{GUID}/`

---

### copy-plugin-packages

Copies built plugin packages (.nupkg) to the solution's pluginpackages folder.

**Usage:**
```yaml
- name: Copy plugin packages
  uses: joshsmithxrm/ppds-alm/.github/actions/copy-plugin-packages@v2
  with:
    source-package: src/PluginPackages/MyProject.PluginPackage/bin/Release/prefix_MyProject.PluginPackage.1.0.0.nupkg
    solution-folder: solutions/MySolution/src
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `source-package` | Yes | - | Path to built plugin package (.nupkg) |
| `solution-folder` | Yes | - | Path to unpacked solution folder |

**Outputs:**

| Output | Description |
|--------|-------------|
| `copied-count` | Number of locations where package was copied |
| `target-path` | Path where package was copied |
| `package-id` | Extracted package ID (without version) |

**Naming Convention:**
- Build output: `prefix_MyProject.PluginPackage.1.0.0.nupkg`
- Solution expects: `prefix_MyProject.PluginPackage.nupkg` (no version)
- Target folder: `pluginpackages/prefix_MyProject.PluginPackage/package/`

---

## Quality Actions

### check-solution

Runs the PowerApps Solution Checker to validate solution quality.

**Usage:**
```yaml
- name: Check solution quality
  id: check
  uses: joshsmithxrm/ppds-alm/.github/actions/check-solution@v2
  with:
    solution-path: ./exports/MySolution_managed.zip
    fail-on-level: High
    geography: unitedstates

- name: Review results
  run: |
    echo "Passed: ${{ steps.check.outputs.passed }}"
    echo "Critical: ${{ steps.check.outputs.critical-count }}"
    echo "High: ${{ steps.check.outputs.high-count }}"
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-path` | Yes | - | Path to solution zip file |
| `fail-on-level` | No | `High` | Fail threshold (see below) |
| `geography` | No | `unitedstates` | Solution Checker geography |
| `output-directory` | No | `./checker-results` | Directory for checker output |
| `rule-level-override` | No | - | Path to rule level override file |

**Severity Levels (in order):**
1. `Critical` - Blocking issues that will cause failures
2. `High` - Serious issues that should be addressed
3. `Medium` - Moderate issues worth reviewing
4. `Low` - Minor issues and best practice suggestions
5. `Informational` - Non-issues, just FYI

**Outputs:**

| Output | Description |
|--------|-------------|
| `passed` | Whether solution passed threshold check |
| `critical-count` | Number of critical issues |
| `high-count` | Number of high severity issues |
| `medium-count` | Number of medium severity issues |
| `low-count` | Number of low severity issues |
| `informational-count` | Number of informational issues |
| `total-count` | Total number of issues |
| `results-file` | Path to SARIF results file |

**Geography Options:**
- `unitedstates`, `europe`, `asia`, `australia`, `japan`, `india`, `canada`, `southamerica`, `uk`, `france`, `uae`, `germany`, `switzerland`, `norway`, `korea`, `southafrica`

---

### analyze-changes

Analyzes git changes to filter out "noise" from Power Platform solution exports.

**Usage:**
```yaml
- name: Stage changes
  run: git add -A

- name: Analyze changes
  id: analyze
  uses: joshsmithxrm/ppds-alm/.github/actions/analyze-changes@v2
  with:
    solution-folder: solutions/MySolution/src
    debug: 'false'

- name: Commit if real changes
  if: steps.analyze.outputs.has-real-changes == 'true'
  run: |
    git commit -m "chore: sync solution"
    git push
```

**Inputs:**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `solution-folder` | Yes | - | Path to unpacked solution folder |
| `debug` | No | `false` | Enable verbose debug logging |

**Outputs:**

| Output | Description |
|--------|-------------|
| `has-real-changes` | Whether real (non-noise) changes were detected |
| `change-summary` | Human-readable summary of changes |
| `noise-count` | Number of noise changes filtered out |
| `real-count` | Number of real changes detected |
| `real-files` | List of files with real changes (newline-separated) |

**Noise Patterns Filtered:**
- Solution.xml version-only changes
- Canvas App DocumentUri/BackgroundImageUri random suffixes
- Workflow workflowName changes (session ID regeneration)
- Whitespace-only file changes
- Git R100 renames (100% identical content)
- MissingDependency version reference changes

**Prerequisites:**
- Changes must be staged (`git add -A`) before calling this action
- Must be run from a git repository

---

## Action Composition Examples

### Full Export with Noise Filtering

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: joshsmithxrm/ppds-alm/.github/actions/setup-pac-cli@v2

  - uses: joshsmithxrm/ppds-alm/.github/actions/pac-auth@v2
    with:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}

  - uses: joshsmithxrm/ppds-alm/.github/actions/export-solution@v2
    with:
      solution-name: MySolution
      output-folder: solutions/MySolution/src

  - run: git add -A

  - id: analyze
    uses: joshsmithxrm/ppds-alm/.github/actions/analyze-changes@v2
    with:
      solution-folder: solutions/MySolution/src

  - if: steps.analyze.outputs.has-real-changes == 'true'
    run: |
      git config user.name "github-actions"
      git config user.email "github-actions@github.com"
      git commit -m "chore: sync solution from Dev"
      git push
```

### Full Build and Deploy

```yaml
steps:
  - uses: actions/checkout@v4

  - id: build
    uses: joshsmithxrm/ppds-alm/.github/actions/build-solution@v2
    with:
      solution-path: MySolution.sln
      run-tests: 'true'

  - uses: joshsmithxrm/ppds-alm/.github/actions/copy-plugin-assemblies@v2
    with:
      source-assembly: ${{ steps.build.outputs.classic-assembly-path }}
      solution-folder: solutions/MySolution/src

  - uses: joshsmithxrm/ppds-alm/.github/actions/setup-pac-cli@v2

  - id: pack
    uses: joshsmithxrm/ppds-alm/.github/actions/pack-solution@v2
    with:
      solution-folder: solutions/MySolution/src
      solution-name: MySolution
      package-type: Managed

  - uses: joshsmithxrm/ppds-alm/.github/actions/pac-auth@v2
    with:
      environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
      tenant-id: ${{ vars.POWERPLATFORM_TENANT_ID }}
      client-id: ${{ vars.POWERPLATFORM_CLIENT_ID }}
      client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}

  - uses: joshsmithxrm/ppds-alm/.github/actions/import-solution@v2
    with:
      solution-path: ${{ steps.pack.outputs.solution-path }}
      solution-name: MySolution
```

## See Also

- [Features Guide](./features.md) - Detailed explanation of advanced features
- [GitHub Quickstart](./github-quickstart.md) - Using reusable workflows
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions

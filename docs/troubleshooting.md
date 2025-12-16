# Troubleshooting Guide

This guide helps resolve common issues with PPDS ALM v2 workflows and actions.

## Authentication Errors

### "AADSTS700016: Application not found"

**Cause:** The Client ID doesn't match any app registration in the specified tenant.

**Solution:**
1. Verify the Client ID is correct
2. Ensure the app registration is in the same tenant
3. Check for typos in the Client ID
4. Verify you're using `${{ vars.POWERPLATFORM_CLIENT_ID }}` (variable, not secret)

### "AADSTS7000215: Invalid client secret"

**Cause:** The client secret is incorrect or expired.

**Solution:**
1. Verify you're using the secret **value**, not the secret **ID**
2. Check if the secret has expired in Azure AD
3. Create a new client secret if needed
4. Update your GitHub Secret: `POWERPLATFORM_CLIENT_SECRET`

### "The user is not a member of the organization"

**Cause:** No application user exists in Dataverse for this app registration.

**Solution:**
1. Go to Power Platform Admin Center
2. Select your environment
3. Go to Settings > Users + permissions > Application users
4. Create an application user for your app registration
5. Assign appropriate security roles (System Administrator for full access)

### "Insufficient privileges"

**Cause:** The application user lacks required permissions.

**Solution:**
1. Check the security roles assigned to the application user
2. For solution operations, ensure the role has:
   - Solution: Create, Read, Write, Delete
   - Plugin assemblies (if deploying plugins)
   - Customization: Publish All
3. Consider using System Administrator for troubleshooting

## Import Errors

### Import Skipped (Version Match)

**Symptom:** Workflow shows "Import skipped - target environment has same or newer version"

**Cause:** This is expected behavior when `skip-if-same-version: true` (default).

**Solution (if you want to force import):**
```yaml
- uses: joshsmithxrm/ppds-alm/.github/actions/import-solution@v2
  with:
    solution-path: ./MySolution_managed.zip
    skip-if-same-version: 'false'
```

### "Cannot start another solution at the same time"

**Cause:** Another import is in progress in the same environment.

**Default Behavior:** v2 automatically retries up to 3 times with 5-minute delays.

**If retries fail:**
1. Check if another pipeline is running against the same environment
2. Check Power Platform Admin Center for stuck import jobs
3. Wait for the other import to complete
4. Increase retry settings if needed:
```yaml
with:
  max-retries: '5'
  retry-delay-seconds: '600'  # 10 minutes
```

### "Solution import failed" (General)

**Cause:** Various - missing dependencies, version conflicts, etc.

**Solution:**
1. Check the workflow logs for specific error messages
2. Check Power Platform Admin Center > Environments > History > Solution History
3. Common issues:
   - **Missing dependencies:** Install required solutions first
   - **Version conflict:** Ensure source version > target version, or disable version check
   - **Component conflict:** Check for customizations blocking import

### "Missing dependency" errors

**Cause:** The solution references components from other solutions not installed in target.

**Solution:**
1. Identify the missing component from the error message
2. Install the required base solution first
3. Consider using solution layering properly
4. Check if a publisher prefix is missing

## Export Errors

### "Solution not found"

**Cause:** The solution unique name doesn't match.

**Solution:**
1. Verify the solution **unique name** (not display name)
2. Check for case sensitivity
3. Ensure the solution exists in the source environment
4. Use `pac solution list` to see available solutions

### PAC CLI `--allowDelete` not working (Linux)

**Symptom:** Removed components remain in repository after export.

**Cause:** Known PAC CLI bug on Linux runners.

**Solution:** PPDS ALM v2 includes automatic workaround:
- The `export-solution` action deletes the solution folder before unpack
- Removed components are properly deleted
- If unpack fails, the folder is restored from git

**If you see this issue:**
1. Ensure you're using v2 actions
2. Check that the workaround is functioning (folder should be deleted before unpack in logs)

### Export produces no changes

**Cause:** May be due to noise filtering (if enabled) or no actual changes.

**Solution:**
1. Check if `filter-noise: true` is set
2. Review the `analyze-changes` output to see what was filtered
3. To see all changes regardless:
```yaml
with:
  filter-noise: false
```

## Build Errors

### ".NET solution file not found"

**Cause:** The build action couldn't locate a `.sln` file.

**Solution:**
1. Specify the path explicitly:
```yaml
- uses: joshsmithxrm/ppds-alm/.github/actions/build-solution@v2
  with:
    solution-path: ./src/MySolution.sln
```
2. Ensure the `.sln` file exists in the repository root or specified path

### Plugin assembly not found after build

**Cause:** Build output location doesn't match expected conventions.

**Solution:**
1. Check the `plugins-folder` input matches your project structure:
```yaml
with:
  plugins-folder: 'src/Plugins'  # Default
```
2. Verify build output exists in `bin/Release` (or specified configuration)
3. Check that build succeeded (review logs)

### Plugin package (.nupkg) not found

**Cause:** NuGet package wasn't created or is in unexpected location.

**Solution:**
1. Ensure your project generates a NuGet package
2. Check `plugin-packages-folder` input:
```yaml
with:
  plugin-packages-folder: 'src/PluginPackages'  # Default
```
3. Verify the package includes version in filename (e.g., `MyPackage.1.0.0.nupkg`)

### Copy plugin assemblies failed

**Symptom:** "No folder matching pattern found in PluginAssemblies"

**Cause:** The solution folder doesn't have the expected plugin assembly folder structure.

**Solution:**
1. Ensure the solution was exported with plugins registered
2. Check that `PluginAssemblies/{AssemblyName}-{GUID}/` folder exists
3. Verify the assembly name pattern matches (dots are removed):
   - Build output: `MyProject.Plugins.dll`
   - Expected folder: `MyProjectPlugins-{GUID}/`

## Solution Checker Errors

### "Solution Checker failed"

**Cause:** Solution has issues exceeding the configured threshold.

**Solution:**
1. Review the checker output in the workflow summary
2. Download the SARIF results file from artifacts
3. Address issues based on severity:
   - Critical: Must fix
   - High: Should fix
   - Medium/Low: Review and plan

4. Adjust threshold if needed:
```yaml
with:
  fail-on-level: Critical  # Only fail on critical issues
```

### "Geography not supported"

**Cause:** Invalid geography specified for Solution Checker.

**Solution:** Use a valid geography:
- `unitedstates` (default)
- `europe`
- `asia`
- `australia`
- `japan`
- `india`
- `canada`
- `southamerica`
- `uk`
- `france`
- `uae`
- `germany`
- `switzerland`
- `norway`
- `korea`
- `southafrica`

## GitHub Actions Specific

### "Cannot find reusable workflow"

**Cause:** Incorrect workflow reference.

**Solution:**
1. Verify the repository path: `joshsmithxrm/ppds-alm`
2. Check the workflow path (note: no `.github` prefix for reusable workflows):
   ```yaml
   # Correct
   uses: joshsmithxrm/ppds-alm/github/workflows/solution-deploy.yml@v2

   # Wrong
   uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v2
   ```
3. Ensure you're using a valid ref (`@v2`, `@main`, etc.)

### "Resource not accessible by integration"

**Cause:** GitHub token lacks required permissions.

**Solution:**
1. Add permissions block to your workflow:
```yaml
permissions:
  contents: read
  actions: read
```

### Environment variables not found

**Symptom:** `${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}` is empty

**Cause:** Variables not configured in GitHub Environment.

**Solution:**
1. Go to Settings > Environments > [Your Environment]
2. Add required variables:
   - `POWERPLATFORM_ENVIRONMENT_URL`
   - `POWERPLATFORM_TENANT_ID`
   - `POWERPLATFORM_CLIENT_ID`
3. Ensure workflow specifies the environment:
```yaml
jobs:
  deploy:
    environment: QA  # Must match your environment name
```

## Debug Mode

### Enable Verbose Logging

**GitHub Actions:**
```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

**For specific actions:**
```yaml
- uses: joshsmithxrm/ppds-alm/.github/actions/analyze-changes@v2
  with:
    solution-folder: solutions/MySolution/src
    debug: 'true'
```

### View PAC CLI Output

PAC CLI commands include full output in workflow logs. Look for:
- Authentication results after `pac auth create`
- Solution list after `pac solution list`
- Import progress during `pac solution import`

## Getting Help

### Collect Information

When reporting issues, include:

1. **Environment details:**
   - GitHub Actions runner OS
   - PAC CLI version (from workflow output)
   - .NET version (if build issues)

2. **Error details:**
   - Full error message
   - Workflow step that failed
   - Relevant logs (sanitize secrets!)

3. **Configuration:**
   - Workflow YAML (sanitize secrets!)
   - Input parameter values
   - Environment URL (can be sanitized)

### Support Channels

- **GitHub Issues:** [ppds-alm Issues](https://github.com/joshsmithxrm/ppds-alm/issues)
- **PPDS.Tools Issues:** [ppds-tools Issues](https://github.com/joshsmithxrm/ppds-tools/issues)
- **Documentation:** Check the docs folder for detailed guides

### FAQ

**Q: Can I use these templates with on-premises Dataverse?**
A: These templates are designed for Dataverse Online. On-premises would require authentication changes.

**Q: Do I need PPDS.Tools module?**
A: Only for plugin operations (`plugin-deploy.yml`, `plugin-extract.yml`). Solution operations use PAC CLI.

**Q: Can I customize the workflows?**
A: Yes! Use composite actions directly for full customization, or fork the repository.

**Q: How do I handle different configurations per environment?**
A: Use GitHub Environments with environment-specific variables and secrets. Use deployment settings files for Power Platform configuration.

**Q: Why is my import being skipped?**
A: Version comparison is enabled by default. Set `skip-if-same-version: false` to always import.

## See Also

- [Features Guide](./features.md) - Understanding advanced features
- [Actions Reference](./actions-reference.md) - Detailed action documentation
- [Authentication Guide](./authentication.md) - Credential setup
- [Migration Guide](./migration-v2.md) - Upgrading from v1

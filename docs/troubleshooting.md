# Troubleshooting Guide

This guide helps resolve common issues with PPDS ALM workflows and templates.

## Common Issues

### Authentication Errors

#### "AADSTS700016: Application not found"

**Cause:** The Client ID doesn't match any app registration in the specified tenant.

**Solution:**
1. Verify the Client ID is correct
2. Ensure the app registration is in the same tenant
3. Check for typos in the Client ID

#### "AADSTS7000215: Invalid client secret"

**Cause:** The client secret is incorrect or expired.

**Solution:**
1. Verify you're using the secret **value**, not the secret **ID**
2. Check if the secret has expired in Azure AD
3. Create a new client secret if needed
4. Update your secrets in GitHub/Azure DevOps

#### "The user is not a member of the organization"

**Cause:** No application user exists in Dataverse for this app registration.

**Solution:**
1. Go to Power Platform Admin Center
2. Select your environment
3. Create an application user for your app registration
4. Assign appropriate security roles

#### "Insufficient privileges"

**Cause:** The application user lacks required permissions.

**Solution:**
1. Check the security roles assigned to the application user
2. Ensure the role has permissions for:
   - Plugin assemblies (Create, Read, Write, Delete)
   - Plugin steps (Create, Read, Write, Delete)
   - Solutions (Read, Write for import)
3. Consider using System Administrator for troubleshooting

### Module Installation Errors

#### "Unable to find module 'PPDS.Tools'"

**Cause:** PowerShell Gallery is inaccessible or module not published.

**Solution:**
1. Check if PowerShell Gallery is accessible
2. Verify the module name is correct
3. Check for proxy/firewall issues in your CI/CD environment
4. Try installing with `-Verbose` flag for more details

#### "Module 'PPDS.Tools' was not installed"

**Cause:** Installation failed silently.

**Solution:**
```powershell
# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set repository as trusted
Set-PSRepository PSGallery -InstallationPolicy Trusted

# Install with verbose output
Install-Module PPDS.Tools -Force -Scope CurrentUser -Verbose
```

### Plugin Deployment Errors

#### "Assembly not found"

**Cause:** The registration file references an assembly that doesn't exist in Dataverse.

**Solution:**
1. Ensure the assembly is uploaded to Dataverse first
2. Check the assembly name matches exactly
3. Verify the assembly is in the correct solution

#### "Plugin step already exists"

**Cause:** Attempting to create a step that already exists.

**Solution:**
1. The deployment should handle this automatically
2. Enable drift detection to identify differences
3. Use `-Force` parameter to overwrite existing steps

#### "Drift detected"

**Cause:** Plugin registrations in Dataverse don't match the registration file.

**Solution:**
1. Review the drift report in the workflow output
2. Decide if you want to:
   - Update Dataverse to match your config (deploy)
   - Update your config to match Dataverse (extract)
3. Use `Remove-DataverseOrphanedSteps` to clean up orphaned steps

### Solution Operations Errors

#### "Solution import failed"

**Cause:** Various - missing dependencies, version conflicts, etc.

**Solution:**
1. Check the import job in Power Platform Admin Center
2. Look for specific error messages
3. Common issues:
   - Missing dependencies: Install required solutions first
   - Version conflict: Ensure source version > target version
   - Customization conflict: Use `--force-overwrite` carefully

#### "Solution not found"

**Cause:** The solution unique name doesn't match.

**Solution:**
1. Verify the solution unique name (not display name)
2. Check for case sensitivity
3. Ensure the solution exists in the source environment

### GitHub Actions Specific

#### "Error: Cannot find reusable workflow"

**Cause:** Incorrect workflow reference.

**Solution:**
1. Verify the repository path: `joshsmithxrm/ppds-alm`
2. Check the workflow path: `.github/workflows/plugin-deploy.yml`
3. Ensure you're using a valid ref (`@v1`, `@main`, etc.)

#### "Resource not accessible by integration"

**Cause:** GitHub token lacks required permissions.

**Solution:**
1. Ensure your workflow has appropriate permissions
2. Add permissions block if needed:
```yaml
permissions:
  contents: read
  actions: read
```

### Azure DevOps Specific

#### "Repository 'ppds-alm' not found"

**Cause:** Repository resource not configured correctly.

**Solution:**
1. Verify the GitHub service connection exists
2. Check the service connection has access to the repository
3. Ensure the repository resource is defined correctly:
```yaml
resources:
  repositories:
    - repository: ppds-alm
      type: github
      name: joshsmithxrm/ppds-alm
      endpoint: 'Your GitHub Service Connection'
```

#### "Template not found"

**Cause:** Incorrect template path or repository reference.

**Solution:**
1. Verify the template path matches exactly
2. Ensure `@ppds-alm` suffix is included
3. Check the ref points to a valid tag/branch

#### "Service connection not found"

**Cause:** The service connection name doesn't match.

**Solution:**
1. Verify the exact name of your service connection
2. Check spelling and case sensitivity
3. Ensure the pipeline has access to the service connection

## Debug Mode

### Enable Verbose Logging

#### GitHub Actions

Add to your workflow:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

#### Azure DevOps

Add system debug variable:
```yaml
variables:
  system.debug: true
```

### PowerShell Debug Output

Add to PowerShell scripts:
```powershell
$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'
```

## Getting Help

### Collect Information

When reporting issues, include:

1. **Environment details:**
   - CI/CD platform (GitHub Actions, Azure DevOps)
   - Runner OS version
   - PowerShell version

2. **Error details:**
   - Full error message
   - Stack trace if available
   - Workflow/pipeline logs

3. **Configuration:**
   - Workflow/pipeline YAML (sanitize secrets!)
   - Registration file (if relevant)
   - Environment URL (can be sanitized)

### Support Channels

- **GitHub Issues:** [ppds-alm Issues](https://github.com/joshsmithxrm/ppds-alm/issues)
- **PPDS.Tools Issues:** [ppds-tools Issues](https://github.com/joshsmithxrm/ppds-tools/issues)
- **Documentation:** Check the docs folder for detailed guides

### FAQ

**Q: Can I use these templates with on-premises Dataverse?**
A: These templates are designed for Dataverse Online. On-premises would require authentication changes.

**Q: Do I need to publish PPDS.Tools to use these templates?**
A: Yes, PPDS.Tools must be available on PowerShell Gallery for the workflows to install it.

**Q: Can I customize the templates?**
A: Yes! Fork the repository and modify templates for your needs. Consider contributing improvements back.

**Q: How do I handle different configurations per environment?**
A: Use separate registration files per environment, or use environment variables to configure behavior.

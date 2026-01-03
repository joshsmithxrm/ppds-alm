# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported |
|---------|-----------|
| v1.x | ✅ |
| < v1.0 | ❌ |

**Recommendation:** Pin to specific version tags (e.g., `@v1.0.0`) for production workflows.

---

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### 1. Do NOT Open a Public Issue

Security vulnerabilities should **not** be reported via public GitHub issues. Public disclosure could put users at risk before a fix is available.

### 2. Report Privately

**Use GitHub's private vulnerability reporting:**
1. Go to the [Security tab](https://github.com/joshsmithxrm/ppds-alm/security)
2. Click "Report a vulnerability"
3. Fill out the form with details

### 3. Include in Your Report

- **Description**: Clear description of the vulnerability
- **Impact**: What an attacker could do (secret exposure, workflow manipulation, etc.)
- **Steps to Reproduce**: Detailed steps or proof-of-concept
- **Affected Workflows/Actions**: Which templates are vulnerable
- **Suggested Fix**: If you have ideas (optional)

### 4. Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Fix Development**: Depends on severity (critical: 7-14 days, high: 14-30 days)
- **Security Release**: Coordinated disclosure after fix is ready

---

## Security Practices

### What We Do

1. **Input/Secret Separation**: Clear distinction between configuration inputs and secrets
2. **Minimal Permissions**: Workflows request only necessary permissions
3. **Pinned Dependencies**: CLI tools installed with specific versions
4. **Code Reviews**: All PRs reviewed for security issues
5. **OIDC Preferred**: Templates prefer OIDC authentication over stored secrets

### Secrets Handling

**Templates separate inputs from secrets:**

```yaml
# ✅ Correct pattern used in our templates
on:
  workflow_call:
    inputs:
      environment-url:        # Non-sensitive
        type: string
    secrets:
      client-secret:          # Sensitive - properly isolated
        required: true
```

**Secrets are never:**
- Logged to workflow output
- Passed as command-line arguments where visible
- Stored in artifacts

### OIDC Authentication (Recommended)

Our templates support OIDC federation, eliminating stored secrets:

```yaml
# GitHub Actions OIDC - no client secret needed
permissions:
  id-token: write  # Required for OIDC

- uses: joshsmithxrm/ppds-alm/.github/actions/pac-auth@v1
  with:
    environment-url: ${{ vars.ENVIRONMENT_URL }}
    tenant-id: ${{ vars.TENANT_ID }}
    client-id: ${{ vars.CLIENT_ID }}
    # No client-secret needed with OIDC
```

See [Azure OIDC Setup](./docs/AZURE_OIDC_SETUP.md) for configuration.

### Workflow Permissions

Our reusable workflows declare minimal permissions:

```yaml
permissions:
  contents: read      # Read repository
  id-token: write     # OIDC token (when needed)
```

**Consumers should follow least-privilege:**
- Only grant permissions workflows actually need
- Use environment protection rules for production deployments
- Require approval for sensitive environment deployments

---

## Known Security Considerations

### 1. Workflow Reference Pinning

Always pin to specific versions in production:

```yaml
# ✅ Secure - pinned to specific version
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1.0.0

# ⚠️ Risky - major version can change
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1

# ❌ Insecure - main branch can change anytime
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@main
```

### 2. Fork Pull Request Security

If you allow workflows on fork PRs, be aware:
- Fork PRs don't have access to repository secrets
- `pull_request_target` grants elevated permissions (use carefully)

Our templates are designed to work with `pull_request` (not `pull_request_target`).

### 3. Artifact Security

Solution exports may contain:
- Connection references (environment-specific)
- Environment variable values
- Canvas app data sources

**Mitigation:** Use deployment settings files to override sensitive values per environment.

### 4. Secret Rotation

Client secrets used in CI/CD should be rotated regularly:
- Rotate every 90 days (maximum)
- Use OIDC to eliminate secrets entirely
- Monitor secret access in Azure AD audit logs

---

## Security Updates

### How to Stay Informed

1. **Watch this repository** (Releases only or All Activity)
2. **Check CHANGELOG.md** for security fixes
3. **Subscribe to GitHub Security Advisories** for this repo

### Applying Security Updates

Update your workflow references to the latest secure version:

```yaml
# Before (vulnerable version)
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1.0.0

# After (patched version)
uses: joshsmithxrm/ppds-alm/.github/workflows/solution-deploy.yml@v1.0.1
```

---

## Security Checklist for Contributors

If you're contributing templates, please review:

- [ ] Secrets passed via `secrets:`, not `inputs:`
- [ ] No secrets logged or exposed in output
- [ ] Minimal workflow permissions declared
- [ ] CLI tools pinned to specific versions
- [ ] Input validation before use
- [ ] Error messages don't leak secret values
- [ ] Shell scripts properly escape variables

---

## Disclosure Policy

### Coordinated Disclosure

We follow **coordinated disclosure**:
1. Reporter notifies us privately
2. We develop and test a fix
3. We release patched templates
4. We publish a security advisory
5. Reporter can publish details (after patch release)

**Typical timeline:** 30-90 days from report to public disclosure

---

## Contact

- **Security Issues**: [GitHub Private Vulnerability Reporting](https://github.com/joshsmithxrm/ppds-alm/security/advisories/new)
- **General Security Questions**: Open a [GitHub Discussion](https://github.com/joshsmithxrm/ppds-alm/discussions)
- **Non-Security Bugs**: Open a [GitHub Issue](https://github.com/joshsmithxrm/ppds-alm/issues)

---

**Thank you for helping keep PPDS ALM secure!**

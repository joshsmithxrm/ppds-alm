# Branching Strategy

This document defines the recommended Git branching model and workflow for Power Platform solution development.

## Branch Overview

We recommend a simplified GitFlow model with two primary branches.

| Branch | Purpose | Protected | Deploys To |
|--------|---------|-----------|------------|
| `main` | Production-ready code | Yes | Prod |
| `develop` | Integration branch | Yes | QA |
| `feature/*` | Feature development | No | - |
| `fix/*` | Bug fixes (normal priority) | No | - |
| `hotfix/*` | Emergency fixes | No | - |

## Branch Flow

```
feature/add-validation ──┐
                         │
feature/new-entity    ───┼──► develop ──► main
                         │      │          │
fix/workflow-bug     ────┘      ▼          ▼
                             QA Env     Prod Env
```

## Branch Details

### `main` Branch

**Purpose:** Represents production-ready code. Every commit to `main` should be deployable to production.

**Rules:**
- Protected branch (no direct commits)
- Requires pull request from `develop`
- Requires at least one approval
- All CI checks must pass

**Deployment:** Pushes to `main` trigger deployment to Production environment.

### `develop` Branch

**Purpose:** Integration branch where features are combined and tested before release.

**Rules:**
- Protected branch
- Receives automated exports from Dev environment (nightly)
- Receives pull requests from feature branches
- Can receive direct commits from automated export pipeline

**Deployment:** Pushes to `develop` trigger deployment to QA environment.

### `feature/*` and `fix/*` Branches

**Purpose:** Isolated development of specific features or bug fixes.

**Naming:**
- `feature/{short-description}` - New functionality
- `fix/{short-description}` - Bug fixes (normal priority)

**Examples:**
```
feature/add-account-validation
feature/new-contact-form
fix/workflow-error-handling
fix/form-validation-bug
```

**Workflow:**
1. Create from `develop`
2. Make changes in Dev environment
3. Export and commit to feature/fix branch
4. Create PR to `develop`
5. Delete after merge

### `hotfix/*` Branches

**Purpose:** Emergency fixes that need to go directly to production.

**Naming:** `hotfix/{issue-description}`

**Examples:**
```
hotfix/fix-critical-workflow
hotfix/security-patch
```

**Workflow:**
1. Create from `main`
2. Make minimal fix
3. PR to `main` (for immediate production deployment)
4. Cherry-pick or merge back to `develop`
5. Delete after merge

## Branch Policy Configuration

### PR to `develop`

| Requirement | Required? |
|-------------|-----------|
| CI pipeline passes | Yes |
| At least 1 approval | Recommended |
| No merge conflicts | Yes |
| Linked work item | Optional |

### PR to `main`

| Requirement | Required? |
|-------------|-----------|
| CI pipeline passes | Yes |
| At least 1 approval | Yes |
| QA sign-off | Yes |
| No merge conflicts | Yes |
| All conversations resolved | Yes |

## Merge Strategy

### Squash Merge: Feature → Develop

**Use squash merge** when merging feature branches into `develop`.

```
feature/add-validation (12 commits) → develop (1 squashed commit)
```

**Why squash:**
| Reason | Explanation |
|--------|-------------|
| Clean history | Feature branches have noisy commits ("WIP", "fix typo") |
| Atomic features | Each feature = one commit, easy to identify and revert |
| Power Platform | Solution exports create many small commits; squashing cleans this up |

### Regular Merge: Develop → Main

**Use regular merge** (merge commit) when merging `develop` into `main`.

```
develop → main (merge commit preserves all feature commits)
```

**Why regular merge:**
| Reason | Explanation |
|--------|-------------|
| Preserves features | Each squashed feature commit flows through to main |
| Release boundaries | Merge commit marks exactly when a release happened |
| Traceability | Easy to trace which feature caused an issue |

## Commit Message Convention

Follow conventional commits for clear history:

```
<type>: <short description>

[optional body]

[optional footer]
```

**Types:**
| Type | Description |
|------|-------------|
| `feat` | New feature or component |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `chore` | Maintenance, dependencies, automated syncs |
| `refactor` | Code restructuring |

**Examples:**
```
feat: add account validation plugin
fix: correct status transition in workflow
docs: update deployment guide
chore: sync solution from Dev environment
```

## Automation Bypass for CI/CD

The nightly export workflow commits directly to `develop`, bypassing branch protection. This is intentional for the ALM pattern.

### Why Automation Bypasses Branch Protection

| Concern | Explanation |
|---------|-------------|
| "Shouldn't all changes require PR?" | No. PRs are for human-authored changes. Automated exports are operational. |
| "What about review?" | QA environment IS the review. Testing validates changes, not XML diff review. |

### Where Gates Should Be

```
Dev → develop → QA       (automated, fast feedback)
QA  → main    → Prod     (gated, human approval required)
```

The human gate belongs at **QA → Prod**, not at **Dev → QA**.

## When to Deviate

### Add Release Branches When:
- You need to maintain multiple production versions
- Formal release cycles require stabilization periods
- Hotfixes need isolation from ongoing development

### Add Environment-Specific Branches When:
- Multiple long-lived environments need different configurations
- UAT requires extended testing periods
- Regulatory requirements mandate branch-per-environment

### Skip Feature Branches When:
- Solo developer working on simple changes
- Automated exports are the only commits
- Changes are trivial (typos, config adjustments)

## See Also

- [ALM_OVERVIEW.md](ALM_OVERVIEW.md) - High-level ALM philosophy
- [ENVIRONMENT_STRATEGY.md](ENVIRONMENT_STRATEGY.md) - Environment configuration
- [Atlassian GitFlow Guide](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) - GitFlow reference

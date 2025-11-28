# GitHub Actions Patterns Reference

## Trigger Events

### Push Events
```yaml
on:
  push:
    branches: [main, develop]
    tags: ['v*']
    paths:
      - 'src/**'
      - '!docs/**'
```

### Pull Request Events
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main]
    paths: ['src/**']
```

### Manual Trigger
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

### Schedule
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

### Release Events
```yaml
on:
  release:
    types: [published]
```

## Common Actions

### Checkout
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0         # Full history for tags
    submodules: recursive  # Include submodules
    ref: develop           # Specific branch
```

### Setup Node.js
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '18'
    cache: 'npm'  # Auto-cache npm dependencies
```

### Setup Python
```yaml
- uses: actions/setup-python@v5
  with:
    python-version: '3.11'
    cache: 'pip'  # Auto-cache pip dependencies
```

### Cache
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Upload Artifact
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 5
```

### Download Artifact
```yaml
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: dist/
```

### Docker Build and Push
```yaml
- uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: |
      myrepo/myimage:latest
      myrepo/myimage:${{ github.sha }}
```

## Caching Strategies

### Node.js
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Python (pip)
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

### Go
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/go/pkg/mod
      ~/.cache/go-build
    key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
```

### Docker Layers
```yaml
- uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Gradle
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*') }}
```

## Workflow Patterns

### Build and Test
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npm test
```

### Deploy on Release
```yaml
name: Deploy

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

### Matrix Testing
```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [16, 18, 20]
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm test
```

### Monorepo CI
```yaml
on:
  push:
    paths:
      - 'packages/api/**'
      - 'packages/web/**'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      api: ${{ steps.changes.outputs.api }}
      web: ${{ steps.changes.outputs.web }}
    steps:
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            api:
              - 'packages/api/**'
            web:
              - 'packages/web/**'

  build-api:
    needs: detect-changes
    if: needs.detect-changes.outputs.api == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building API"
```

### Scheduled Maintenance
```yaml
name: Scheduled Tasks

on:
  schedule:
    - cron: '0 3 * * 1'  # Monday 3 AM UTC

jobs:
  update-deps:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm update
      - uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: update dependencies'
```

## Secrets Management

```yaml
# Access secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# In step
- run: deploy
  env:
    DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

**Best practices:**
- Never log secrets
- Use least privilege
- Rotate regularly
- Use environment protection rules
- Mask sensitive outputs

## Permissions

```yaml
# Minimal permissions per job
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
```

**Available permissions:**
- `contents`: Read/write repository contents
- `issues`: Create/modify issues
- `pull-requests`: Create/modify PRs
- `packages`: Publish packages
- `deployments`: Create deployments
- `statuses`: Set commit statuses
- `checks`: Create check runs

**Default**: Read-only for all scopes
**Recommendation**: Explicit minimal permissions per job

## Security Considerations

- **Pin actions to commit SHA**: `uses: actions/checkout@abc123`
- **Minimal permissions**: Explicit per-job permissions
- **Fork PRs**: Be cautious with `pull_request_target`
- **Secret access**: Restrict to required workflows
- **Token scope**: Use GITHUB_TOKEN with minimal scope
- **Third-party actions**: Review source code, check reputation
- **Code injection**: Avoid `${{ github.event.issue.title }}` in `run`
- **Environment protection**: Require approval for production

## Advanced Features

### Reusable Workflows
```yaml
# .github/workflows/reusable.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"

# Caller workflow
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
    with:
      environment: production
```

### Concurrency Control
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Environment Protection
```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://app.example.com
    runs-on: ubuntu-latest
```

### OIDC Authentication
```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/my-role
      aws-region: us-east-1
```

## Homelab Integration

- **Self-hosted runners**: Deploy on VMs in management VLAN
- **Container deployment**: Build images, push to registry, deploy via Ansible
- **Infrastructure updates**: Trigger Terraform/Ansible on release
- **Testing**: Run integration tests against homelab services
- **Monitoring**: Workflow status notifications
- **Secrets**: Pull from 1Password or HashiCorp Vault

### Self-hosted Runner Setup
```yaml
jobs:
  deploy:
    runs-on: self-hosted
    labels: [homelab, linux]
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
```

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Workflow not triggering | Event filters wrong | Check branch names, paths |
| Action not found | Wrong action name/version | Verify marketplace listing |
| Permission denied | Token scope | Review workflow permissions |
| Secret not found | Wrong name/scope | Check secret name, environment |
| Cache not restored | Key mismatch | Verify cache key, check limits |
| Artifact upload failed | Path/size issue | Check path, file size, retention |
| Runner out of resources | Large build | Use larger runner, optimize |
| Timeout | Long-running job | Increase timeout-minutes |
| Syntax error | YAML issue | Validate YAML, check indentation |

### Debug Commands

```bash
# List workflow runs
gh run list --workflow=<name>

# View run details
gh run view <run-id>

# Download logs
gh run download <run-id>

# Watch run in real-time
gh run watch <run-id>

# Trigger manual workflow
gh workflow run <workflow> -f input=value
```

### Debug Mode

Enable step debug logging:
```yaml
# In workflow
env:
  ACTIONS_STEP_DEBUG: true
```

Or set repository secret `ACTIONS_STEP_DEBUG` to `true`.

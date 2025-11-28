# Terraform Troubleshooting Reference

## Common Errors

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| State lock timeout | Stale lock | `terraform force-unlock <lock-id>` (carefully) |
| Provider not found | Not initialized | `terraform init` |
| Resource exists | Manual creation | `terraform import <resource> <id>` |
| Cycle detected | Circular dependency | Review `depends_on`, remove cycle |
| Invalid syntax | HCL error | `terraform validate`, check quotes |
| Backend init required | Backend changed | `terraform init -reconfigure` |
| Version constraint | Provider mismatch | Update version constraints |

## Diagnostic Commands

### Validation and Syntax

```bash
terraform validate              # Check configuration validity
terraform fmt -check            # Check formatting without changes
terraform fmt -diff             # Show what would change
```

### State Inspection

```bash
terraform state list            # List all resources in state
terraform state show <resource> # Show resource details
terraform refresh               # Update state from real infrastructure
```

### Planning and Debugging

```bash
terraform plan                  # Preview changes
terraform plan -out=plan.tfplan # Save plan for later apply
TF_LOG=DEBUG terraform plan     # Enable debug logging
TF_LOG=TRACE terraform plan     # Maximum verbosity
terraform graph | dot -Tsvg > graph.svg  # Dependency graph
```

### State Management

```bash
terraform state mv <src> <dst>  # Rename/move resource in state
terraform state rm <resource>   # Remove resource from state (not infrastructure)
terraform import <resource> <id> # Import existing resource
```

### Lock Issues

```bash
# List locks (if using S3/DynamoDB backend)
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

## Troubleshooting Workflows

### Plan Shows Unexpected Changes

1. Check for manual changes: `terraform refresh`
2. Review state: `terraform state show <resource>`
3. Compare with actual infrastructure
4. Check for provider bugs or version differences

### Resource Won't Create

1. Validate config: `terraform validate`
2. Check dependencies exist
3. Enable debug: `TF_LOG=DEBUG terraform apply`
4. Review provider documentation

### State Corruption

1. Backup current state
2. Try: `terraform refresh`
3. Consider: `terraform state rm` + `terraform import`
4. Last resort: Edit state JSON (dangerous)

### Import Existing Resources

```bash
# 1. Write resource block in .tf file
# 2. Import the resource
terraform import aws_instance.example i-1234567890abcdef0

# 3. Run plan to verify
terraform plan
```

## Debug Environment Variables

| Variable | Purpose |
|----------|---------|
| `TF_LOG` | Log level: TRACE, DEBUG, INFO, WARN, ERROR |
| `TF_LOG_PATH` | Write logs to file |
| `TF_LOG_CORE` | Core terraform logging only |
| `TF_LOG_PROVIDER` | Provider plugin logging only |
| `TF_INPUT` | Disable interactive prompts (set to 0) |

## Recovery Procedures

### Recover Lost State

```bash
# If state was accidentally deleted but resources exist:
# 1. Create minimal config
# 2. Import each resource
terraform import <resource_type>.<name> <id>
```

### Reset Provider Lock

```bash
# If .terraform.lock.hcl is corrupt
rm .terraform.lock.hcl
terraform init -upgrade
```

### Clean Init

```bash
# Full re-initialization
rm -rf .terraform
rm .terraform.lock.hcl
terraform init
```

---
name: terraform
description: |
  Terraform infrastructure-as-code reference for HCL syntax, state management,
  module design, and provider configuration. Use when working with Terraform
  configurations (.tf files), running terraform commands, troubleshooting state
  issues, or designing modules. Includes Telmate Proxmox provider patterns.
  Triggers: terraform, tfstate, .tf files, HCL, modules, providers, proxmox_vm_qemu.
---

# Terraform Skill

Infrastructure-as-code reference for Terraform configurations, state management, and provider patterns.

## Quick Reference

```bash
# Core workflow
terraform init              # Initialize, download providers
terraform validate          # Syntax validation
terraform fmt -recursive    # Format HCL files
terraform plan              # Preview changes
terraform apply             # Apply changes

# Inspection
terraform state list                    # List resources in state
terraform state show <resource>         # Show resource details
terraform graph | dot -Tsvg > graph.svg # Dependency graph

# Debug
TF_LOG=DEBUG terraform plan 2>debug.log
```

## Core Workflow

```
init → validate → fmt → plan → apply
```

1. **init**: Download providers, initialize backend
2. **validate**: Check syntax and configuration validity
3. **fmt**: Ensure consistent formatting
4. **plan**: Preview what will change (review carefully)
5. **apply**: Execute changes

## Reference Files

Load on-demand based on task:

| Topic | File | When to Load |
|-------|------|--------------|
| Proxmox Gotchas | [proxmox/gotchas.md](references/proxmox/gotchas.md) | Critical provider issues, workarounds |
| Proxmox Auth | [proxmox/authentication.md](references/proxmox/authentication.md) | Provider config, API tokens |
| Proxmox VMs | [proxmox/vm-qemu.md](references/proxmox/vm-qemu.md) | proxmox_vm_qemu resource patterns |
| Proxmox Errors | [proxmox/troubleshooting.md](references/proxmox/troubleshooting.md) | Common errors, debugging |
| State | [state-management.md](references/state-management.md) | Backends, locking, operations |
| Modules | [module-design.md](references/module-design.md) | Module patterns, composition |
| Security | [security.md](references/security.md) | Secrets, state security |
| External | [external-resources.md](references/external-resources.md) | Official docs, links |

## Validation Checklist

Before `terraform apply`:

- [ ] `terraform init` completed successfully
- [ ] `terraform validate` passes
- [ ] `terraform fmt` applied
- [ ] `terraform plan` reviewed (check destroy/replace operations)
- [ ] Backend configured correctly (for team environments)
- [ ] State locking enabled (if remote backend)
- [ ] Sensitive variables marked `sensitive = true`
- [ ] Provider versions pinned in `terraform.tf`
- [ ] No secrets in version control
- [ ] Blast radius assessed (what could break?)

## Variable Precedence

(highest to lowest)

1. `-var` flag: `terraform apply -var="name=value"`
2. `-var-file` flag: `terraform apply -var-file=prod.tfvars`
3. `*.auto.tfvars` files (alphabetically)
4. `terraform.tfvars` file
5. `TF_VAR_*` environment variables
6. Variable defaults in `variables.tf`

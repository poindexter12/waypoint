# Terraform to OpenTofu Migration

## Overview

OpenTofu is a drop-in replacement for Terraform. Migration is typically straightforward.

## Steps

### 1. Install OpenTofu

```bash
# macOS
brew install opentofu

# Linux (Debian/Ubuntu)
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh
```

### 2. Verify Installation

```bash
tofu version
```

### 3. Replace Commands

Simply replace `terraform` with `tofu`:

```bash
# Before
terraform init
terraform plan
terraform apply

# After
tofu init
tofu plan
tofu apply
```

### 4. State Compatibility

- OpenTofu can read Terraform state files directly
- No migration of state required
- Backend configurations work the same

### 5. Provider Registry

OpenTofu uses its own registry but can access Terraform providers:

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"  # Works the same
      version = "~> 3.0"
    }
  }
}
```

## Common Issues

### Provider Not Found

If a provider isn't in the OpenTofu registry:

```hcl
terraform {
  required_providers {
    custom = {
      source = "registry.terraform.io/vendor/provider"
    }
  }
}
```

### Version Constraints

OpenTofu versions may differ from Terraform:
- Check `required_version` in your configs
- Update if needed: `required_version = ">= 1.6.0"`

## Rollback

If needed, you can switch back to Terraform:
- State files remain compatible
- Just use `terraform` commands instead of `tofu`

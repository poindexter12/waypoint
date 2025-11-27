# State Management

## Remote Backend (Recommended)

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # State locking
  }
}
```

### S3-Compatible (MinIO, Ceph)

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "project/terraform.tfstate"
    region = "us-east-1"  # Required but ignored

    endpoint                    = "https://minio.example.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
```

## State Operations

```bash
# List resources
terraform state list
terraform state list proxmox_vm_qemu.*

# Show resource details
terraform state show proxmox_vm_qemu.web

# Rename resource
terraform state mv proxmox_vm_qemu.old proxmox_vm_qemu.new

# Move to module
terraform state mv proxmox_vm_qemu.web modules.web.proxmox_vm_qemu.main

# Remove from state (doesn't destroy)
terraform state rm proxmox_vm_qemu.orphaned

# Import existing resource
terraform import proxmox_vm_qemu.web pve1/qemu/100

# Update state from infrastructure
terraform refresh
```

## State Migration

```bash
# Change backend - updates terraform block, then:
terraform init -migrate-state

# Reinitialize without migration
terraform init -reconfigure
```

## State Locking

Prevents concurrent modifications. Enable via backend config:
- S3: `dynamodb_table`
- Consul: Built-in
- HTTP: `lock_address`

### Force Unlock (Emergency)

```bash
# Only when certain no operation running
terraform force-unlock LOCK_ID
```

## Troubleshooting

### State Lock Timeout

```
Error: Error acquiring state lock
```

1. Wait for other operation
2. Verify no process running
3. `terraform force-unlock LOCK_ID` if safe

### State Drift

```
Plan shows unexpected changes
```

```bash
terraform refresh  # Update state from real infra
terraform plan     # Review changes
```

### Corrupted State

1. Restore from backup
2. `terraform state pull > backup.tfstate`
3. Last resort: `terraform state rm` and re-import

# Proxmox Automation Tools

Integration patterns for managing Proxmox with Terraform and Ansible.

## Tool Selection Guide

| Task | Recommended Tool | Rationale |
|------|-----------------|-----------|
| VM/LXC provisioning | Terraform | Declarative state, idempotent, handles dependencies |
| Template creation | Packer | Repeatable builds, version-controlled |
| Post-boot configuration | Ansible | Agent-based, procedural, good for drift |
| One-off VM operations | Ansible | Quick tasks, no state file needed |
| Dynamic inventory | Ansible | Query running VMs for configuration |
| Bulk VM creation | Terraform | count/for_each, parallel creation |
| Snapshot management | Either | Terraform for lifecycle, Ansible for ad-hoc |
| Cluster administration | CLI/API | Direct access for maintenance tasks |

## Terraform Integration

### Provider

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://proxmox.example.com:8006/api2/json"
  pm_api_token_id     = "terraform@pve!mytoken"
  pm_api_token_secret = var.pm_api_token_secret
}
```

### Common Patterns

```hcl
# Clone from template
resource "proxmox_vm_qemu" "vm" {
  name        = "myvm"
  target_node = "joseph"
  clone       = "tmpl-ubuntu-2404-standard"
  full_clone  = true

  cores   = 2
  memory  = 4096

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "50G"
        }
      }
    }
  }
}
```

### Skill Reference

Load terraform skill for detailed patterns:
- `terraform/references/proxmox/gotchas.md` - Critical issues
- `terraform/references/proxmox/vm-qemu.md` - VM resource patterns
- `terraform/references/proxmox/authentication.md` - API setup

## Ansible Integration

### Collection

```bash
ansible-galaxy collection install community.general
```

### Common Patterns

```yaml
# Clone VM
- name: Clone from template
  community.general.proxmox_kvm:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    node: joseph
    vmid: 300
    name: myvm
    clone: tmpl-ubuntu-2404-standard
    full: true
    timeout: 500

# Start VM
- name: Start VM
  community.general.proxmox_kvm:
    # ... auth ...
    vmid: 300
    state: started
```

### Skill Reference

Load ansible skill for detailed patterns:
- `ansible/references/proxmox/modules.md` - All Proxmox modules
- `ansible/references/proxmox/gotchas.md` - Common issues
- `ansible/references/proxmox/dynamic-inventory.md` - Auto-discovery

## Terraform vs Ansible Decision

### Use Terraform When

- Creating infrastructure from scratch
- Managing VM lifecycle (create, update, destroy)
- Need state tracking and drift detection
- Deploying multiple similar VMs (for_each)
- Complex dependencies between resources
- Team collaboration with state locking

### Use Ansible When

- Configuring VMs after creation
- Ad-hoc operations (start/stop specific VMs)
- Dynamic inventory needed for other playbooks
- Quick one-off tasks
- No state file management desired
- Integration with existing Ansible workflows

### Use Both When

- Terraform provisions VMs
- Ansible configures them post-boot
- Ansible uses Proxmox dynamic inventory to find Terraform-created VMs

## Hybrid Workflow Example

```
1. Packer builds VM template
   └── packer build ubuntu-2404.pkr.hcl

2. Terraform provisions VMs from template
   └── terraform apply
   └── Outputs: VM IPs, hostnames

3. Ansible configures VMs
   └── Uses Proxmox dynamic inventory OR
   └── Uses Terraform output as inventory

4. Ongoing management
   └── Terraform for infrastructure changes
   └── Ansible for configuration drift
```

## API Token Sharing

Both tools can share the same API token:

```bash
# Create shared token
pveum user add automation@pve
pveum aclmod / -user automation@pve -role PVEAdmin
pveum user token add automation@pve shared --privsep 0
```

Store in shared secrets management (1Password, Vault, etc.).

## Common Gotchas

| Issue | Terraform | Ansible |
|-------|-----------|---------|
| VMID | Auto-assigns if not specified | Must specify manually |
| Cloud-init changes | Use replace_triggered_by | Limited support, use API |
| State tracking | Yes (tfstate) | No state file |
| Parallel operations | Yes (configurable) | Yes (forks) |
| Template name vs ID | Supports both | Supports both |
| Timeout handling | Provider config | Module parameter |

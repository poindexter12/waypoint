# Proxmox Provider Gotchas

Critical issues when using Telmate Proxmox provider with Terraform.

## 1. Cloud-Init Changes Not Tracked

Terraform does **not** detect changes to cloud-init snippet file contents.

```hcl
# PROBLEM: Changing vendor-data.yml won't trigger replacement
resource "proxmox_vm_qemu" "vm" {
  cicustom = "vendor=local:snippets/vendor-data.yml"
}

# SOLUTION: Use replace_triggered_by
resource "local_file" "vendor_data" {
  filename = "vendor-data.yml"
  content  = templatefile("vendor-data.yml.tftpl", { ... })
}

resource "proxmox_vm_qemu" "vm" {
  cicustom = "vendor=local:snippets/vendor-data.yml"

  lifecycle {
    replace_triggered_by = [
      local_file.vendor_data.content_base64sha256
    ]
  }
}
```

## 2. Storage Type vs Storage Pool

Different concepts - don't confuse:

```hcl
disks {
  scsi {
    scsi0 {
      disk {
        storage = "local-lvm"  # Pool NAME (from Proxmox datacenter)
        size    = "50G"
      }
    }
  }
}
scsihw = "virtio-scsi-single"  # Controller TYPE
```

- **Storage pool** = Where data stored (local-lvm, ceph-pool, nfs-share)
- **Disk type** = Interface (scsi, virtio, ide, sata)

## 3. Network Interface Naming

Proxmox VMs get predictable names by device order:

| NIC Order | Guest Name |
|-----------|------------|
| First | ens18 |
| Second | ens19 |
| Third | ens20 |

**NOT** eth0, eth1. Configure cloud-init netplan matching `ens*`.

## 4. API Token Expiration

Long operations (20+ VMs) can exceed token lifetime.

```hcl
provider "proxmox" {
  pm_api_token_id     = "terraform@pve!mytoken"
  pm_api_token_secret = var.pm_api_token_secret
  pm_timeout          = 1200  # 20 minutes for large operations
}
```

Use API tokens (longer-lived) not passwords.

## 5. Full Clone vs Linked Clone

```hcl
full_clone = true   # Independent copy - safe, slower, more storage
full_clone = false  # References template - BREAKS if template modified
```

**Always use `full_clone = true` for production.** Linked clones only for disposable test VMs.

# proxmox_vm_qemu Resource

## Basic VM from Template

```hcl
resource "proxmox_vm_qemu" "vm" {
  name        = "my-vm"
  target_node = "pve1"
  clone       = "ubuntu-template"
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 8192
  cpu     = "host"

  onboot = true
  agent  = 1  # QEMU guest agent

  scsihw = "virtio-scsi-single"
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

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-init
  os_type   = "cloud-init"
  ciuser    = "ubuntu"
  sshkeys   = var.ssh_public_key
  ipconfig0 = "ip=dhcp"
  # Static: ipconfig0 = "ip=192.168.1.10/24,gw=192.168.1.1"

  # Custom cloud-init
  cicustom = "vendor=local:snippets/vendor-data.yml"
}
```

## Lifecycle Management

```hcl
lifecycle {
  prevent_destroy = true  # Block accidental deletion

  ignore_changes = [
    network,  # Ignore manual changes
  ]

  replace_triggered_by = [
    local_file.cloud_init.content_base64sha256
  ]

  create_before_destroy = true  # Blue-green deployment
}
```

## Multiple VMs with for_each

```hcl
variable "vms" {
  type = map(object({
    node   = string
    cores  = number
    memory = number
  }))
}

resource "proxmox_vm_qemu" "vm" {
  for_each    = var.vms
  name        = each.key
  target_node = each.value.node
  cores       = each.value.cores
  memory      = each.value.memory
  # ...
}
```

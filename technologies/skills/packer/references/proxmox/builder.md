# Proxmox Builder Reference

## Builder Types

| Builder | Use Case |
|---------|----------|
| `proxmox-iso` | Build from ISO, full installation |
| `proxmox-clone` | Clone existing VM/template |

## proxmox-iso Full Reference

```hcl
source "proxmox-iso" "template-name" {
  # ─────────────────────────────────────────────
  # CONNECTION
  # ─────────────────────────────────────────────
  proxmox_url              = "https://pve.local:8006/api2/json"
  username                 = "packer@pam!packer-token"
  token                    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  insecure_skip_tls_verify = true  # For self-signed certs
  node                     = "pve"

  # ─────────────────────────────────────────────
  # VM IDENTIFICATION
  # ─────────────────────────────────────────────
  vm_id                = 9000
  vm_name              = "ubuntu-22.04-template"
  template_description = "Ubuntu 22.04 - Built ${formatdate("YYYY-MM-DD", timestamp())}"

  # ─────────────────────────────────────────────
  # ISO SOURCE
  # ─────────────────────────────────────────────
  # Option 1: Existing ISO on storage
  iso_file = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"

  # Option 2: Download ISO
  # iso_url          = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  # iso_checksum     = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  # iso_storage_pool = "local"

  unmount_iso = true  # Unmount after install

  # ─────────────────────────────────────────────
  # HARDWARE
  # ─────────────────────────────────────────────
  cores    = 2
  sockets  = 1
  memory   = 2048
  cpu_type = "host"  # Or "kvm64", "qemu64"

  os       = "l26"   # Linux 2.6+ kernel
  machine  = "q35"   # Or "pc" for legacy
  bios     = "ovmf"  # UEFI, or "seabios" for legacy

  qemu_agent = true  # Install qemu-guest-agent

  # ─────────────────────────────────────────────
  # STORAGE
  # ─────────────────────────────────────────────
  scsi_controller = "virtio-scsi-single"

  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "local-lvm"
    format       = "raw"        # Or "qcow2"
    cache_mode   = "writeback"  # Performance option
    discard      = true         # Enable TRIM
    ssd          = true         # If on SSD storage
  }

  # Additional disk
  # disks {
  #   type         = "scsi"
  #   disk_size    = "50G"
  #   storage_pool = "data"
  # }

  # ─────────────────────────────────────────────
  # NETWORK
  # ─────────────────────────────────────────────
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    vlan_tag = ""        # Optional VLAN
    firewall = false     # Disable during build
  }

  # ─────────────────────────────────────────────
  # CLOUD-INIT
  # ─────────────────────────────────────────────
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # ─────────────────────────────────────────────
  # SSH
  # ─────────────────────────────────────────────
  ssh_username = "ubuntu"
  ssh_password = "packer"
  ssh_timeout  = "30m"

  # Or use SSH keys
  # ssh_private_key_file = "~/.ssh/packer_key"

  ssh_handshake_attempts = 50

  # ─────────────────────────────────────────────
  # BOOT
  # ─────────────────────────────────────────────
  http_directory = "http"  # Serves user-data

  boot      = "order=scsi0;ide2"  # Disk first, then ISO
  boot_wait = "5s"

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]

  # ─────────────────────────────────────────────
  # EFI
  # ─────────────────────────────────────────────
  efi_config {
    efi_storage_pool  = "local-lvm"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }
}
```

## proxmox-clone Reference

```hcl
source "proxmox-clone" "from-template" {
  # Connection (same as proxmox-iso)
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true
  node                     = "pve"

  # Clone source
  clone_vm    = "ubuntu-22.04-base"  # Source VM/template name
  # Or by ID
  # clone_vm_id = 9000

  # New VM
  vm_id   = 9001
  vm_name = "ubuntu-22.04-configured"

  # Optionally modify hardware
  cores  = 4
  memory = 4096

  # SSH to run provisioners
  ssh_username = "ubuntu"
  ssh_password = "packer"
}
```

## API Token Setup

Create dedicated Packer user and token:

```bash
# Create user
pveum user add packer@pam

# Create role with minimum permissions
pveum role add Packer -privs \
  "VM.Allocate,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,\
VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,\
VM.Config.Options,VM.Monitor,VM.Audit,VM.PowerMgmt,\
Datastore.AllocateSpace,Datastore.Allocate,Datastore.Audit,\
SDN.Use,Sys.Modify"

# Assign role
pveum aclmod / -user packer@pam -role Packer

# Create API token
pveum user token add packer@pam packer-token --privsep=0
```

## Common Issues

### VM ID Conflict

```
Error: VM 9000 already exists
```

Use dynamic VM ID or check existing:
```bash
pvesh get /cluster/nextid
```

### Storage Pool Not Found

Verify storage pools:
```bash
pvesm status
```

### ISO Not Found

List available ISOs:
```bash
pvesh get /nodes/pve/storage/local/content --content iso
```

### Network Bridge Not Found

Check available bridges:
```bash
cat /etc/network/interfaces
# Or
ip link show type bridge
```

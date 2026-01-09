# Cloud-Init with Packer

## Overview

Cloud-init enables unattended installation and configuration. For Ubuntu, this uses the "autoinstall" feature.

## Required Files

Place in `http/` directory (served by Packer's HTTP server):

### user-data

```yaml
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us

  identity:
    hostname: ubuntu-template
    username: ubuntu
    # Password: packer (generated with mkpasswd --method=SHA-512)
    password: "$6$rounds=4096$xyz$..."

  ssh:
    install-server: true
    allow-pw: true

  packages:
    - qemu-guest-agent
    - cloud-init

  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
    - chmod 440 /target/etc/sudoers.d/ubuntu

  storage:
    layout:
      name: lvm
```

### meta-data

```yaml
instance-id: packer
local-hostname: packer
```

## Boot Command for Autoinstall

```hcl
http_directory = "http"

boot_command = [
  "<esc><wait>",
  "e<wait>",
  "<down><down><down><end>",
  " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
  "<f10>"
]
```

**Explanation:**
- `<esc>` - Access GRUB menu
- `e` - Edit boot entry
- Navigate to kernel line
- Append autoinstall datasource URL
- `<f10>` - Boot

## Cloud-Init for Proxmox Templates

Enable cloud-init drive for runtime customization:

```hcl
source "proxmox-iso" "ubuntu" {
  # Enable cloud-init
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # ... rest of config
}
```

This creates a cloud-init drive that Proxmox can customize when cloning.

## Runtime Configuration

When VMs are created from the template, cloud-init handles:

- Hostname
- Network configuration
- SSH keys
- User creation

Configure in Proxmox:
```bash
qm set 100 --ciuser admin
qm set 100 --cipassword secure
qm set 100 --sshkey ~/.ssh/id_rsa.pub
qm set 100 --ipconfig0 ip=dhcp
```

## Password Generation

```bash
# Generate SHA-512 password hash
mkpasswd --method=SHA-512 --rounds=4096

# Or with Python
python3 -c "import crypt; print(crypt.crypt('packer', crypt.mksalt(crypt.METHOD_SHA512)))"
```

## Debugging Cloud-Init

After SSH access:

```bash
# Check cloud-init status
cloud-init status

# View logs
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log

# Re-run cloud-init (careful!)
cloud-init clean --logs
cloud-init init
```

## Common Issues

### user-data not found

- Check HTTP server is running during build
- Verify boot_command URL is correct
- Check firewall allows HTTP from VM to host

### Invalid YAML

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('http/user-data'))"
```

### Autoinstall not triggered

- Ensure `#cloud-config` is first line
- Check autoinstall version matches Ubuntu version
- Verify kernel cmdline has autoinstall parameter

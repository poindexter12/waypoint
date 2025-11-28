# Cloud-init Templates Reference

YAML templates, module reference, commands, and troubleshooting for cloud-init VM provisioning.

## Quick Reference

**Common Commands:**
```bash
cloud-init status                        # Check completion status
cloud-init analyze show                  # Boot time breakdown
cloud-init schema --config-file user.yaml # Validate YAML
cloud-init clean && reboot               # Re-run for testing
cloud-init query ds                      # Datasource info
```

**Key Files:**
- `/var/log/cloud-init.log` - Detailed execution log
- `/var/log/cloud-init-output.log` - Command output
- `/run/cloud-init/result.json` - Execution result

## Cloud-config Structure

### Basic Template

```yaml
#cloud-config
# Basic VM setup

# Hostname
hostname: vm-name
fqdn: vm-name.domain.local

# Users
users:
  - name: admin
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...

# Packages
packages:
  - qemu-guest-agent
  - vim
  - curl

# Run commands
runcmd:
  - echo "Setup complete" > /etc/motd

# SSH configuration
ssh_pwauth: false
disable_root: true

# Timezone
timezone: America/New_York
```

## Datasources

| Datasource | Use Case | Config Method |
|------------|----------|---------------|
| NoCloud | Testing, custom setups | Files on seed disk or HTTP |
| ConfigDrive | OpenStack, cloud platforms | ISO 9660 or VFAT volume |
| Proxmox | Proxmox VE | Cloud-init tab + snippets |
| EC2/Azure/GCP | Public clouds | Instance metadata service |

### NoCloud Details

- Local filesystem or URL-based config
- Files: user-data, meta-data on seed disk or HTTP
- Proxmox: Can use with snippets storage

### Proxmox Details

- Native Proxmox datasource
- Config: Through Proxmox cloud-init tab
- Storage: Snippets storage for custom configs
- Path: `/var/lib/vz/snippets/` (default)

## Common Modules

| Module | Purpose | Stage |
|--------|---------|-------|
| bootcmd | Commands before networking | Local |
| runcmd | Commands after system up | Final |
| users | User and group creation | Network |
| ssh | SSH key/daemon config | Network |
| packages | Package installation | Network |
| package_update | Run package manager update | Network |
| package_upgrade | Upgrade installed packages | Network |
| write_files | Create files with content | Network |
| mounts | Configure mount points | Local |
| disk_setup | Partition and format disks | Local |
| growpart | Resize root partition | Local |
| timezone | Set system timezone | Network |
| hostname/fqdn | Set hostname | Network |
| power_state | Reboot/shutdown after completion | Final |

## User Management

```yaml
users:
  - name: username
    gecos: "Full Name"
    groups: sudo,docker
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: true  # Disable password login
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...
    passwd: $6$...  # Hashed password (mkpasswd --method=SHA-512)
```

## SSH Configuration

```yaml
# Disable password authentication
ssh_pwauth: false

# Disable root login
disable_root: true

# Import SSH keys from GitHub/Launchpad
ssh_import_id:
  - gh:username
  - lp:username

# SSH authorized keys
ssh_authorized_keys:
  - ssh-rsa AAAAB3...
```

## Package Management

```yaml
# Update package database
package_update: true

# Upgrade packages
package_upgrade: true

# Install packages
packages:
  - qemu-guest-agent
  - vim
  - htop
  - net-tools

# Package repository configuration
apt:
  sources:
    custom-repo:
      source: "deb [arch=amd64] https://repo.example.com/ubuntu focal main"
      keyid: KEYID
```

## Network Configuration

### DHCP (default)
```yaml
# No additional config needed, DHCP is default
```

### Static IP (network-config file)
```yaml
version: 2
ethernets:
  eth0:
    addresses:
      - 192.168.1.10/24
    gateway4: 192.168.1.1
    nameservers:
      addresses:
        - 192.168.1.1
        - 8.8.8.8
```

### VLAN Configuration
```yaml
version: 2
ethernets:
  eth0:
    dhcp4: false
vlans:
  eth0.20:
    id: 20
    link: eth0
    addresses:
      - 192.168.20.10/24
    gateway4: 192.168.20.1
```

### Interface Renaming (netplan)
```yaml
version: 2
ethernets:
  mgmt0:
    match:
      name: ens18
    set-name: mgmt0
    addresses: [192.168.5.10/24]
    gateway4: 192.168.5.1
```

## Write Files

```yaml
write_files:
  - path: /etc/myconfig.conf
    content: |
      # Configuration file
      option1 = value1
      option2 = value2
    permissions: '0644'
    owner: root:root

  - path: /usr/local/bin/script.sh
    content: |
      #!/bin/bash
      echo "Custom script"
    permissions: '0755'
    owner: root:root

  # From base64
  - path: /etc/ssl/cert.pem
    encoding: b64
    content: BASE64_ENCODED_CONTENT
    permissions: '0600'
```

## Boot Commands

### bootcmd vs runcmd

| Aspect | bootcmd | runcmd |
|--------|---------|--------|
| Timing | Early (before networking) | Late (after system up) |
| Frequency | Every boot | First boot only |
| Use for | Time-sensitive init, network prerequisites | Most setup commands |

```yaml
bootcmd:
  - echo "Early boot command"

runcmd:
  - echo "Late boot command"
  - systemctl enable my-service
  - /usr/local/bin/setup.sh
```

## Disk Configuration

```yaml
# Grow root partition to fill disk
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

# Additional disk setup
disk_setup:
  /dev/sdb:
    table_type: gpt
    layout: true
    overwrite: false

# Filesystem setup
fs_setup:
  - label: data
    filesystem: ext4
    device: /dev/sdb1

# Mount configuration
mounts:
  - [/dev/sdb1, /data, ext4, defaults, 0, 2]
```

## VM Template Creation (Proxmox)

```bash
# 1. Create VM from cloud image
qm create 9000 --name ubuntu-template --memory 2048 --net0 virtio,bridge=vmbr0

# 2. Import cloud image
qm importdisk 9000 ubuntu-22.04-cloud.img local-lvm

# 3. Attach disk
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# 4. Add cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# 5. Configure boot order
qm set 9000 --boot c --bootdisk scsi0

# 6. Configure serial console
qm set 9000 --serial0 socket --vga serial0

# 7. Configure cloud-init defaults
qm set 9000 --ipconfig0 ip=dhcp
qm set 9000 --ciuser admin
qm set 9000 --sshkeys /path/to/keys.pub

# 8. Convert to template
qm template 9000

# 9. Clone from template
qm clone 9000 100 --name new-vm --full
```

## Image Preparation Script

```bash
#!/bin/bash
# Clean VM for template conversion

# Remove SSH host keys
rm -f /etc/ssh/ssh_host_*

# Remove machine ID
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Clean cloud-init
cloud-init clean

# Clean package cache
apt clean

# Clean logs
find /var/log -type f -delete

# Clean temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clean shell history
history -c
cat /dev/null > ~/.bash_history
```

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Cloud-init not running | Datasource detection failed | Check datasource config |
| SSH login failed | SSH keys/user config wrong | Verify keys format, user config |
| Network not configured | network-config issue | Check network-config, datasource |
| Package installation failed | Network/repo issue | Check network, repository access |
| Syntax error | Invalid YAML | Validate with `cloud-init schema` |
| Slow boot | Too many modules | Disable unnecessary modules |
| Commands not running | runcmd syntax error | Check logs for errors |
| Template clone issues | Improper cleanup | Re-run image preparation |

### Debug Commands

```bash
# Check status
cloud-init status

# Boot time breakdown
cloud-init analyze show

# View detailed log
cat /var/log/cloud-init.log

# View command output
cat /var/log/cloud-init-output.log

# Validate config
cloud-init schema --config-file user-data.yaml

# Query datasource
cloud-init query ds

# Re-run for testing
cloud-init clean && reboot

# Debug single module
cloud-init single --name <module> --frequency always

# Render final config
cloud-init devel render

# Network verification
ip addr
ip route
```

## Proxmox Cloud-init Integration

- **Cloud-init tab** in Proxmox UI
- Configure: User, password, SSH keys, network
- **Snippets storage** for custom user-data:
  - Storage type: Directory
  - Content: Snippets
  - Path: `/var/lib/vz/snippets/` (default)
  - Custom config: `/var/lib/vz/snippets/vm-100-user.yaml`

## Validation Checklist

- [ ] Cloud-init installed and enabled
- [ ] Datasource correctly configured
- [ ] User-data syntax valid (YAML)
- [ ] SSH keys properly formatted
- [ ] Network configuration appropriate
- [ ] Required packages listed
- [ ] qemu-guest-agent installed
- [ ] Timezone configured
- [ ] Hostname/FQDN set
- [ ] Security: SSH keys only, root disabled
- [ ] File permissions correct
- [ ] Commands syntax valid
- [ ] Template cleanup completed
- [ ] Test clone successful
- [ ] Boot time acceptable
- [ ] Logs checked for errors

## VM Template Best Practices

- Use official cloud images (Ubuntu, Debian, etc.)
- Install qemu-guest-agent for better integration
- Configure serial console for access
- Enable cloud-init
- Set reasonable defaults (SSH keys, user)
- Document template creation process
- Version templates (name with date/version)
- Test template with clone before production use
- Keep templates updated (security patches)
- Use snippets storage for custom cloud-init configs

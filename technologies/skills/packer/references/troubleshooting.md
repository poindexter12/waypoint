# Packer Troubleshooting

## SSH Connection Issues

### Timeout waiting for SSH

**Symptoms:**
```
==> proxmox-iso.ubuntu: Waiting for SSH to become available...
==> proxmox-iso.ubuntu: Timeout waiting for SSH.
```

**Causes and fixes:**

1. **Boot command timing**: Increase `boot_wait` if the VM isn't ready
   ```hcl
   boot_wait = "10s"  # Try 10-15s instead of 5s
   ```

2. **Boot command errors**: Check VNC console for boot errors
   - Connect to Proxmox VNC during build
   - Verify boot command reaches installer

3. **Cloud-init not running**: Verify user-data is served
   ```bash
   # Check HTTP server is running during build
   curl http://PACKER_IP:PORT/user-data
   ```

4. **Wrong SSH credentials**: Match user-data and Packer config
   ```hcl
   ssh_username = "ubuntu"   # Must match user-data user
   ssh_password = "packer"   # Must match user-data password
   ```

5. **Firewall blocking**: Check Proxmox firewall settings
   - Disable firewall on network adapter during build
   - Or allow SSH from Packer host

### SSH authentication failures

**Check:**
- Password vs key authentication mismatch
- User not created correctly by cloud-init
- Password not set correctly

```hcl
# Force password auth
ssh_password = "packer"
ssh_handshake_attempts = 50
```

## Proxmox API Issues

### 401 Unauthorized

**Fix:** Check API token format and permissions

```hcl
# Token format: user@realm!tokenname
username = "packer@pam!packer-token"
token    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Required permissions:
- VM.Allocate
- VM.Config.*
- VM.PowerMgmt
- Datastore.AllocateSpace
- Datastore.Allocate
- Sys.Modify (for cloud-init)

### 500 Internal Server Error

**Common causes:**
- Storage pool doesn't exist
- VM ID already in use
- ISO not found
- Insufficient disk space

### SSL/TLS errors

```hcl
insecure_skip_tls_verify = true  # For self-signed certs
```

## Build Hangs

### Stuck at boot

1. Connect to VNC console in Proxmox
2. Check if waiting for input
3. Verify boot_command keystrokes

### Stuck during provisioning

```bash
# Enable debug mode
PACKER_LOG=1 packer build .

# Or step through
packer build -debug .
```

## Cloud-Init Issues

### user-data not applied

1. Verify HTTP server is accessible:
   ```bash
   curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/user-data
   ```

2. Check autoinstall syntax:
   ```yaml
   #cloud-config
   autoinstall:
     version: 1
     # ...
   ```

3. Verify cloud-init ran:
   ```bash
   # After SSH
   cat /var/log/cloud-init-output.log
   ```

### Wrong network config

Ensure meta-data is minimal for DHCP:
```yaml
# meta-data (empty or minimal)
instance-id: packer
local-hostname: packer
```

## ISO Issues

### ISO not found

```hcl
# Correct format
iso_file = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
#          ^storage:type/filename

# List available ISOs
# pvesh get /nodes/pve/storage/local/content --content iso
```

### ISO checksum mismatch

```hcl
iso_checksum = "sha256:xxxxxx"
# Or skip validation (not recommended)
iso_checksum = "none"
```

## Performance Issues

### Build is slow

1. Use local storage for disks during build
2. Increase CPU/memory temporarily
3. Use cache for package downloads

### Large image size

Add cleanup provisioner:
```bash
#!/bin/bash
# cleanup.sh
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
cloud-init clean --logs
```

## Debug Commands

```bash
# Verbose output
PACKER_LOG=1 packer build template.pkr.hcl 2>&1 | tee build.log

# Step-by-step
packer build -debug template.pkr.hcl

# Validate only
packer validate template.pkr.hcl

# Check plugin versions
packer plugins installed
```

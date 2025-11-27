# Proxmox Troubleshooting

## VM Creation Stuck

```
Timeout waiting for VM to be created
```

**Causes**: Template missing, storage full, network unreachable
**Debug**: Check Proxmox task log in web UI

## Clone Failed

```
VM template not found
```

**Check**: `qm list | grep template-name`
**Causes**: Template doesn't exist, wrong node, permission issue

## SSH Timeout

```
Timeout waiting for SSH
```

**Debug**:
1. VM console in Proxmox UI
2. `cloud-init status` on VM
3. `ip addr` to verify network

**Causes**: Cloud-init failed, network misconfigured, firewall

## State Drift

```
Plan shows changes for unchanged resources
```

**Causes**: Manual changes in Proxmox UI, provider bug
**Fix**:
```bash
terraform refresh
terraform plan  # Verify
```

## API Errors

```
500 Internal Server Error
```

**Causes**: Invalid config, resource constraints, API timeout
**Debug**: Check `/var/log/pveproxy/access.log` on Proxmox node

## Permission Denied

```
Permission check failed
```

**Fix**: Verify API token has required permissions:
```bash
pveum acl list
pveum user permissions terraform@pve
```

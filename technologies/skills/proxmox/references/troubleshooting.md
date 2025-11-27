# Proxmox Troubleshooting Reference

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| VM won't start | Lock, storage, resources | `qm unlock`, check storage, verify resources |
| Migration failed | No shared storage, resources | Verify shared storage, check target capacity |
| Cluster issues | Quorum, network, time | `pvecm status`, check NTP, network |
| Storage unavailable | Mount failed, network | Check mount, network access |
| High load | Resource contention | Identify bottleneck, rebalance VMs |
| Network issues | Bridge, VLAN, firewall | `brctl show`, check tags, firewall rules |
| Backup failed | Disk space, VM state | Check space, storage access |
| Template not found | Not downloaded | Download from Proxmox repo |
| API errors | Auth, permissions | Check token, user permissions |

## Diagnostic Commands

### Cluster Health

```bash
pvecm status                     # Quorum and node status
pvecm nodes                      # List cluster members
systemctl status pve-cluster     # Cluster service
systemctl status corosync        # Corosync service
```

### Node Health

```bash
pveversion -v                    # Proxmox version info
uptime                           # Load and uptime
free -h                          # Memory usage
df -h                            # Disk space
top -bn1 | head -20              # Process overview
```

### VM Diagnostics

```bash
qm status <vmid>                 # VM state
qm config <vmid>                 # VM configuration
qm showcmd <vmid>                # QEMU command line
qm unlock <vmid>                 # Clear locks
qm monitor <vmid>                # QEMU monitor access
```

### Container Diagnostics

```bash
pct status <ctid>                # Container state
pct config <ctid>                # Container configuration
pct enter <ctid>                 # Enter container shell
pct unlock <ctid>                # Clear locks
```

### Storage Diagnostics

```bash
pvesm status                     # Storage status
df -h                            # Disk space
mount | grep -E 'nfs|ceph'       # Mounted storage
zpool status                     # ZFS pool status (if using ZFS)
ceph -s                          # Ceph status (if using Ceph)
```

### Network Diagnostics

```bash
brctl show                       # Bridge configuration
ip link                          # Network interfaces
ip addr                          # IP addresses
ip route                         # Routing table
bridge vlan show                 # VLAN configuration
```

### Log Files

```bash
# Cluster logs
journalctl -u pve-cluster
journalctl -u corosync

# VM/Container logs
journalctl | grep <vmid>
tail -f /var/log/pve/tasks/*

# Firewall logs
journalctl -u pve-firewall

# Web interface logs
journalctl -u pveproxy
```

## Troubleshooting Workflows

### VM Won't Start

1. Check for locks: `qm unlock <vmid>`
2. Verify storage: `pvesm status`
3. Check resources: `free -h`, `df -h`
4. Review config: `qm config <vmid>`
5. Check logs: `journalctl | grep <vmid>`
6. Try manual start: `qm start <vmid> --debug`

### Migration Failure

1. Verify shared storage: `pvesm status`
2. Check target resources: `pvesh get /nodes/<target>/status`
3. Verify network: `ping <target-node>`
4. Check version match: `pveversion` on both nodes
5. Review migration logs

### Cluster Quorum Lost

1. Check status: `pvecm status`
2. Identify online nodes
3. If majority lost, set expected: `pvecm expected <n>`
4. Recover remaining nodes
5. Rejoin lost nodes when available

### Storage Mount Failed

1. Check network: `ping <storage-server>`
2. Verify mount: `mount | grep <storage>`
3. Try manual mount
4. Check permissions on storage server
5. Review `/var/log/syslog`

### High CPU/Memory Usage

1. Identify culprit: `top`, `htop`
2. Check VM resources: `qm monitor <vmid>` → `info balloon`
3. Review resource allocation across cluster
4. Consider migration or resource limits

## Recovery Procedures

### Remove Failed Node

```bash
# On healthy node
pvecm delnode <failed-node>

# Clean up node-specific configs
rm -rf /etc/pve/nodes/<failed-node>
```

### Force Stop Locked VM

```bash
# Remove lock
qm unlock <vmid>

# If still stuck, find and kill QEMU process
ps aux | grep <vmid>
kill <pid>

# Force cleanup
qm stop <vmid> --skiplock
```

### Recover from Corrupt Config

```bash
# Backup current config
cp /etc/pve/qemu-server/<vmid>.conf /root/<vmid>.conf.bak

# Edit config manually
nano /etc/pve/qemu-server/<vmid>.conf

# Or restore from backup
qmrestore <backup> <vmid>
```

## Health Check Script

```bash
#!/bin/bash
echo "=== Cluster Status ==="
pvecm status

echo -e "\n=== Node Resources ==="
for node in $(pvecm nodes | awk 'NR>1 {print $3}'); do
  echo "--- $node ---"
  pvesh get /nodes/$node/status --output-format yaml | grep -E '^(cpu|memory):'
done

echo -e "\n=== Storage Status ==="
pvesm status

echo -e "\n=== Running VMs ==="
qm list | grep running

echo -e "\n=== Running Containers ==="
pct list | grep running
```

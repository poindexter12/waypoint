# Proxmox CLI Tools Reference

## qm - VM Management

```bash
# List and status
qm list                          # List all VMs
qm status <vmid>                 # VM status
qm config <vmid>                 # Show VM config

# Power operations
qm start <vmid>                  # Start VM
qm stop <vmid>                   # Force stop
qm shutdown <vmid>               # ACPI shutdown
qm reboot <vmid>                 # ACPI reboot
qm reset <vmid>                  # Hard reset
qm suspend <vmid>                # Suspend to RAM
qm resume <vmid>                 # Resume from suspend

# Configuration
qm set <vmid> --memory 4096      # Set memory
qm set <vmid> --cores 4          # Set CPU cores
qm set <vmid> --name newname     # Rename VM

# Disk operations
qm resize <vmid> scsi0 +10G      # Extend disk
qm move-disk <vmid> scsi0 <storage>  # Move disk

# Snapshots
qm snapshot <vmid> <snapname>    # Create snapshot
qm listsnapshot <vmid>           # List snapshots
qm rollback <vmid> <snapname>    # Rollback
qm delsnapshot <vmid> <snapname> # Delete snapshot

# Templates and clones
qm template <vmid>               # Convert to template
qm clone <vmid> <newid>          # Clone VM

# Migration
qm migrate <vmid> <target-node>  # Live migrate

# Troubleshooting
qm unlock <vmid>                 # Remove lock
qm showcmd <vmid>                # Show QEMU command
qm monitor <vmid>                # QEMU monitor
qm guest cmd <vmid> <command>    # Guest agent command
```

## pct - Container Management

```bash
# List and status
pct list                         # List all containers
pct status <ctid>                # Container status
pct config <ctid>                # Show config

# Power operations
pct start <ctid>                 # Start container
pct stop <ctid>                  # Stop container
pct shutdown <ctid>              # Graceful shutdown
pct reboot <ctid>                # Reboot

# Access
pct enter <ctid>                 # Enter shell
pct exec <ctid> -- <command>     # Run command
pct console <ctid>               # Attach console

# Configuration
pct set <ctid> --memory 2048     # Set memory
pct set <ctid> --cores 2         # Set CPU cores
pct set <ctid> --hostname name   # Set hostname

# Disk operations
pct resize <ctid> rootfs +5G     # Extend rootfs
pct move-volume <ctid> <vol> <storage>  # Move volume

# Snapshots
pct snapshot <ctid> <snapname>   # Create snapshot
pct listsnapshot <ctid>          # List snapshots
pct rollback <ctid> <snapname>   # Rollback

# Templates
pct template <ctid>              # Convert to template
pct clone <ctid> <newid>         # Clone container

# Migration
pct migrate <ctid> <target-node> # Migrate container

# Troubleshooting
pct unlock <ctid>                # Remove lock
pct push <ctid> <src> <dst>      # Copy file to container
pct pull <ctid> <src> <dst>      # Copy file from container
```

## pvecm - Cluster Management

```bash
# Status
pvecm status                     # Cluster status
pvecm nodes                      # List nodes
pvecm qdevice                    # QDevice status

# Node operations
pvecm add <node>                 # Join cluster
pvecm delnode <node>             # Remove node
pvecm updatecerts                # Update SSL certs

# Recovery
pvecm expected <votes>           # Set expected votes
```

## pvesh - API Shell

```bash
# GET requests
pvesh get /nodes                 # List nodes
pvesh get /nodes/<node>/status   # Node status
pvesh get /nodes/<node>/qemu     # List VMs on node
pvesh get /nodes/<node>/qemu/<vmid>/status/current  # VM status
pvesh get /storage               # List storage
pvesh get /cluster/resources     # All cluster resources

# POST/PUT requests
pvesh create /nodes/<node>/qemu -vmid <id> ...   # Create VM
pvesh set /nodes/<node>/qemu/<vmid>/config ...   # Modify VM

# DELETE requests
pvesh delete /nodes/<node>/qemu/<vmid>           # Delete VM
```

## vzdump - Backup

```bash
# Basic backup
vzdump <vmid>                    # Backup VM
vzdump <ctid>                    # Backup container

# Options
vzdump <vmid> --mode snapshot    # Snapshot mode
vzdump <vmid> --compress zstd    # With compression
vzdump <vmid> --storage backup   # To specific storage
vzdump <vmid> --mailto admin@example.com  # Email notification

# Backup all
vzdump --all                     # All VMs and containers
vzdump --pool <pool>             # All in pool
```

## qmrestore / pct restore

```bash
# Restore VM
qmrestore <backup.vma> <vmid>
qmrestore <backup.vma> <vmid> --storage local-lvm

# Restore container
pct restore <ctid> <backup.tar>
pct restore <ctid> <backup.tar> --storage local-lvm
```

## Useful Combinations

```bash
# Check resources on all nodes
for node in joseph maxwell everette; do
  echo "=== $node ==="
  pvesh get /nodes/$node/status | jq '{cpu:.cpu, memory:.memory}'
done

# Stop all VMs on a node
qm list | awk 'NR>1 {print $1}' | xargs -I {} qm stop {}

# List VMs with their IPs (requires guest agent)
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
  echo -n "$vmid: "
  qm guest cmd $vmid network-get-interfaces 2>/dev/null | jq -r '.[].["ip-addresses"][]?.["ip-address"]' | head -1
done
```

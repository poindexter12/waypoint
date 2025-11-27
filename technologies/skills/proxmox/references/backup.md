# Proxmox Backup Reference

## vzdump Overview

Built-in backup tool for VMs and containers.

```bash
# Basic backup
vzdump <vmid>

# With options
vzdump <vmid> --mode snapshot --storage backup-nfs --compress zstd

# Backup all VMs
vzdump --all --compress zstd
```

## Backup Modes

| Mode | Downtime | Method | Use Case |
|------|----------|--------|----------|
| stop | Full | Shutdown, backup, start | Consistent, any storage |
| suspend | Brief | Pause, backup, resume | Running state preserved |
| snapshot | None | LVM/ZFS/Ceph snapshot | Production, requires snapshot storage |

### Mode Selection

```bash
# Stop mode (most consistent)
vzdump <vmid> --mode stop

# Suspend mode (preserves RAM state)
vzdump <vmid> --mode suspend

# Snapshot mode (live, requires compatible storage)
vzdump <vmid> --mode snapshot
```

## Backup Formats

| Format | Type | Compression |
|--------|------|-------------|
| VMA | VMs | Native Proxmox format |
| tar | Containers | Standard tar archive |

## Compression Options

| Type | Speed | Ratio | CPU |
|------|-------|-------|-----|
| none | Fastest | 1:1 | Low |
| lzo | Fast | Good | Low |
| gzip | Moderate | Better | Medium |
| zstd | Fast | Best | Medium |

Recommendation: `zstd` for best balance.

```bash
vzdump <vmid> --compress zstd
```

## Storage Configuration

```bash
# Backup to specific storage
vzdump <vmid> --storage backup-nfs

# Check available backup storage
pvesm status | grep backup
```

## Scheduled Backups

Configure in Datacenter → Backup:

- Schedule (cron format)
- Selection (all, pool, specific VMs)
- Storage destination
- Mode and compression
- Retention policy

### Retention Policy

```
keep-last: 3      # Keep last N backups
keep-daily: 7     # Keep daily for N days
keep-weekly: 4    # Keep weekly for N weeks
keep-monthly: 6   # Keep monthly for N months
```

## Restore Operations

### Full Restore

```bash
# Restore VM
qmrestore <backup-file> <vmid>

# Restore to different VMID
qmrestore <backup-file> <new-vmid>

# Restore container
pct restore <ctid> <backup-file>
```

### Restore Options

```bash
# Restore to different storage
qmrestore <backup> <vmid> --storage local-lvm

# Force overwrite existing VM
qmrestore <backup> <vmid> --force
```

### File-Level Restore

```bash
# Mount backup for file extraction
# (Use web UI: Backup → Restore → File Restore)
```

## Proxmox Backup Server (PBS)

Dedicated backup server with deduplication.

### Benefits

- Deduplication across backups
- Encryption at rest
- Verification and integrity checks
- Efficient incremental backups
- Remote backup sync

### Integration

Add PBS storage:

```bash
pvesm add pbs <storage-id> \
  --server <pbs-server> \
  --datastore <datastore> \
  --username <user>@pbs \
  --fingerprint <fingerprint>
```

## Backup Best Practices

- Store backups on separate storage from VMs
- Use snapshot mode for production VMs
- Test restores regularly
- Offsite backup copy for disaster recovery
- Monitor backup job completion
- Set appropriate retention policy

## Troubleshooting

| Issue | Check |
|-------|-------|
| Backup fails | Storage space, VM state, permissions |
| Slow backup | Mode (snapshot faster), compression, network |
| Restore fails | Storage compatibility, VMID conflicts |
| Snapshot fails | Storage doesn't support snapshots |

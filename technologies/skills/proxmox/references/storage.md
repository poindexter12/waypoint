# Proxmox Storage Reference

## Storage Types

### Local Storage

| Type | Features | Use Case |
|------|----------|----------|
| Directory | Simple, any filesystem | Basic storage |
| LVM | Block device, raw performance | Performance |
| LVM-thin | Thin provisioning, snapshots | Efficient space |
| ZFS | Compression, snapshots, high perf | Production |

Limitations: No live migration, single node only.

### Shared Storage

| Type | Features | Use Case |
|------|----------|----------|
| NFS | File-based, simple | Shared access |
| Ceph RBD | Distributed block, HA | Production HA |
| iSCSI | Network block | SAN integration |
| GlusterFS | Distributed file | File sharing |

Benefits: Live migration, HA, shared access.

## Content Types

Configure what each storage can hold:

| Content | Description | File Types |
|---------|-------------|------------|
| images | VM disk images | .raw, .qcow2 |
| iso | ISO images for install | .iso |
| vztmpl | Container templates | .tar.gz |
| backup | Backup files | .vma, .tar |
| rootdir | Container root FS | directories |
| snippets | Cloud-init, hooks | .yaml, scripts |

## Storage Configuration

### Add NFS Storage

```bash
pvesm add nfs <storage-id> \
  --server <nfs-server> \
  --export <export-path> \
  --content images,iso,backup
```

### Add Ceph RBD

```bash
pvesm add rbd <storage-id> \
  --monhost <mon1>,<mon2>,<mon3> \
  --pool <pool-name> \
  --content images,rootdir
```

### Check Storage Status

```bash
pvesm status                    # All storage status
pvesh get /storage              # API query
df -h                           # Disk space
```

## Disk Formats

| Format | Features | Performance |
|--------|----------|-------------|
| raw | No overhead, full allocation | Fastest |
| qcow2 | Snapshots, thin provisioning | Moderate |

Recommendation: Use `raw` for production, `qcow2` for dev/snapshots.

## Disk Cache Modes

| Mode | Safety | Performance | Use Case |
|------|--------|-------------|----------|
| none | Safe | Good | Default, recommended |
| writeback | Unsafe | Best | Non-critical, battery backup |
| writethrough | Safe | Moderate | Compatibility |
| directsync | Safest | Slow | Critical data |

## Storage Performance

### Enable Discard (TRIM)

For SSD thin provisioning:

```
scsi0: local-lvm:vm-100-disk-0,discard=on
```

### I/O Thread

Dedicated I/O thread per disk:

```
scsi0: local-lvm:vm-100-disk-0,iothread=1
```

### I/O Limits

Throttle disk bandwidth:

```
# In VM config
bwlimit: <KiB/s>
iops_rd: <iops>
iops_wr: <iops>
```

## Cloud-Init Storage

Cloud-init configs stored in `snippets` content type:

```bash
# Upload cloud-init files
scp user-data.yaml root@proxmox:/var/lib/vz/snippets/

# Or to named storage
scp user-data.yaml root@proxmox:/mnt/pve/<storage>/snippets/
```

Reference in VM:

```
cicustom: user=<storage>:snippets/user-data.yaml
```

## Backup Storage

### Recommended Configuration

- Separate storage for backups
- NFS or dedicated backup server
- Sufficient space for retention policy

### Backup Retention

Configure in Datacenter → Backup:

```
keep-last: 3
keep-daily: 7
keep-weekly: 4
keep-monthly: 6
```

## Troubleshooting

### Disk Usage

```bash
df -h                           # Filesystem usage
du -sh /* 2>/dev/null | sort -h # Directory sizes
lsblk                           # Block device listing
```

### I/O Performance

```bash
iostat -x 1 5                   # Disk I/O stats
iotop                           # Real-time I/O by process
```

### Ceph Diagnostics

```bash
ceph status                     # Overall status
ceph health detail              # Health issues
ceph osd tree                   # OSD topology
ceph df                         # Space usage
ceph osd pool ls detail         # Pool details
```

### NFS Diagnostics

```bash
showmount -e <server>           # List NFS exports
mount | grep nfs                # Mounted NFS shares
nfsstat -c                      # Client statistics
```

### iSCSI Diagnostics

```bash
iscsiadm -m discovery -t st -p <target-ip>  # Discover targets
iscsiadm -m session                          # Active sessions
iscsiadm -m node -T <target> -p <ip> --login # Login to target
```

### Common Storage Errors

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| Ceph degraded | OSD down, network | Check `ceph status`, OSD logs |
| NFS mount failed | Export, network | Verify exports, check network |
| Slow performance | Network, IOPS | Check jumbo frames, disk IOPS |
| Out of space | Capacity | `ceph df`, identify growth |
| Storage unavailable | Mount failed | Check mount, network access |

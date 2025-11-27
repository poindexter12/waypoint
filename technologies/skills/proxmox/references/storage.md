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

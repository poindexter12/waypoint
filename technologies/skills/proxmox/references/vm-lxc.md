# VM vs LXC Reference

## Decision Matrix

### Use VM (QEMU/KVM) When

- Running Windows or non-Linux OS
- Need full kernel isolation
- Running untrusted workloads
- Complex hardware passthrough needed
- Different kernel version required
- GPU passthrough required

### Use LXC When

- Running Linux services
- Need lightweight, fast startup
- Comfortable with shared kernel
- Want better density/performance
- Simple application containers
- Development environments

## QEMU/KVM VMs

Full hardware virtualization with any OS support.

### Hardware Configuration

| Setting | Options | Recommendation |
|---------|---------|----------------|
| CPU type | host, kvm64, custom | `host` for performance |
| Boot | UEFI, BIOS | UEFI for modern OS |
| Display | VNC, SPICE, NoVNC | NoVNC for web access |

### Storage Controllers

| Type | Performance | Use Case |
|------|-------------|----------|
| VirtIO | Fastest | Linux, Windows with drivers |
| SCSI | Fast | General purpose |
| SATA | Moderate | Compatibility |
| IDE | Slow | Legacy OS |

### Network Adapters

| Type | Performance | Use Case |
|------|-------------|----------|
| VirtIO | Fastest | Linux, Windows with drivers |
| E1000 | Good | Compatibility |
| RTL8139 | Slow | Legacy OS |

### Features

- Snapshots (requires compatible storage)
- Templates for rapid cloning
- Live migration (requires shared storage)
- Hardware passthrough (GPU, USB, PCI)

## LXC Containers

OS-level virtualization with shared kernel.

### Container Types

| Type | Security | Use Case |
|------|----------|----------|
| Unprivileged | Higher (recommended) | Production workloads |
| Privileged | Lower | Docker-in-LXC, NFS mounts |

### Resource Controls

- CPU cores and limits
- Memory hard/soft limits
- Disk I/O throttling
- Network bandwidth limits

### Storage Options

- Bind mounts from host
- Volume storage
- ZFS datasets

### Features

- Fast startup (seconds)
- Lower memory overhead
- Higher density per host
- Templates from Proxmox repo

## Migration Considerations

### VM Migration Requirements

- Shared storage (Ceph, NFS, iSCSI)
- Same CPU architecture
- Compatible Proxmox versions
- Network connectivity between nodes

### LXC Migration Requirements

- Shared storage for live migration
- Same architecture
- Unprivileged preferred for portability

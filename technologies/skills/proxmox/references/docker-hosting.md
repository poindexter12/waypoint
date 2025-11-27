# Docker Workloads on Proxmox

Best practices for hosting Docker containers on Proxmox VE.

## Hosting Options

| Option | Isolation | Overhead | Complexity | Recommendation |
|--------|-----------|----------|------------|----------------|
| VM + Docker | Full | Higher | Low | **Recommended** |
| LXC + Docker | Shared kernel | Lower | High | Avoid |
| Bare metal Docker | None | Lowest | N/A | Not on Proxmox |

## VM for Docker (Recommended)

### Template Selection

Use Docker-ready templates (102+):

| Template | Docker Pre-installed |
|----------|---------------------|
| 102 (docker) | Yes |
| 103 (github-runner) | Yes |
| 104 (pihole) | Yes |

### VM Sizing

| Workload | CPU | RAM | Disk |
|----------|-----|-----|------|
| Light (1-3 containers) | 2 | 4 GB | 50 GB |
| Medium (4-10 containers) | 4 | 8 GB | 100 GB |
| Heavy (10+ containers) | 8+ | 16+ GB | 200+ GB |

### Storage Backend

| Proxmox Storage | Docker Suitability | Notes |
|-----------------|-------------------|-------|
| local-lvm | Good | Default, fast |
| ZFS | Best | Snapshots, compression |
| Ceph | Good | Distributed, HA |
| NFS | Moderate | Shared access, slower |

### Network Configuration

```
Proxmox Node
├── vmbr0 (bridge) → VM eth0 → Docker bridge network
└── vmbr12 (high-speed) → VM eth1 → Docker macvlan (optional)
```

## Docker in LXC (Not Recommended)

If you must run Docker in LXC:

### Requirements

1. **Privileged container** or nesting enabled
2. **AppArmor** profile unconfined
3. **Keyctl** feature enabled

### LXC Options

```bash
# Proxmox GUI: Options → Features
nesting: 1
keyctl: 1

# Or in /etc/pve/lxc/<vmid>.conf
features: keyctl=1,nesting=1
lxc.apparmor.profile: unconfined
```

### Known Issues

- Some Docker storage drivers don't work
- Overlay filesystem may have issues
- Reduced security isolation
- Complex debugging (two container layers)

## Resource Allocation

### CPU

```bash
# VM config - dedicate cores to Docker host
cores: 4
cpu: host  # Pass through CPU features
```

### Memory

```bash
# VM config - allow some overcommit for containers
memory: 8192
balloon: 4096  # Minimum memory
```

### Disk I/O

For I/O intensive containers (databases):

```bash
# VM disk options
cache: none       # Direct I/O for consistency
iothread: 1       # Dedicated I/O thread
ssd: 1            # If on SSD storage
```

## GPU Passthrough for Containers

For transcoding (Plex) or ML workloads:

### 1. Proxmox: Pass GPU to VM

```bash
# /etc/pve/qemu-server/<vmid>.conf
hostpci0: 0000:01:00.0,pcie=1
```

### 2. VM: Install NVIDIA Container Toolkit

```bash
# In VM
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 3. Docker Compose

```yaml
services:
  plex:
    image: linuxserver/plex
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

## Backup Strategy

### VM-level (Recommended)

Proxmox vzdump backs up entire Docker host including all containers:

```bash
vzdump <vmid> --mode snapshot --storage backup --compress zstd
```

### Application-level

For consistent database backups, stop or flush before VM backup:

```bash
# Pre-backup hook
docker exec postgres pg_dump -U user db > /backup/db.sql
```

## Monitoring

### From Proxmox

- VM CPU, memory, network, disk via Proxmox UI
- No visibility into individual containers

### From Docker Host

```bash
# Resource usage per container
docker stats

# System-wide
docker system df
```

### Recommended Stack

```yaml
# On Docker host
services:
  prometheus:
    image: prom/prometheus
  cadvisor:
    image: gcr.io/cadvisor/cadvisor
  grafana:
    image: grafana/grafana
```

## Skill References

For Docker-specific patterns:
- `docker/references/compose.md` - Compose file structure
- `docker/references/networking.md` - Network modes
- `docker/references/volumes.md` - Data persistence
- `docker/references/proxmox/hosting.md` - Detailed hosting guide

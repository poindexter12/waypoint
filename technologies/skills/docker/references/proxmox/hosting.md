# Docker on Proxmox VMs

Best practices for running Docker workloads on Proxmox VE.

## Template Selection

Use Docker-ready templates (102+) which have Docker pre-installed:

| Template ID | Name | Docker? |
|-------------|------|---------|
| 100 | tmpl-ubuntu-2404-base | No |
| 101 | tmpl-ubuntu-2404-standard | No |
| 102 | tmpl-ubuntu-2404-docker | Yes |
| 103 | tmpl-ubuntu-2404-github-runner | Yes |
| 104 | tmpl-ubuntu-2404-pihole | Yes |

**DO NOT** install Docker via cloud-init on templates 102+.

## VM vs LXC for Docker

| Factor | VM (QEMU) | LXC Unprivileged | LXC Privileged |
|--------|-----------|------------------|----------------|
| Docker support | Full | Limited | Works but risky |
| Isolation | Complete | Shared kernel | Shared kernel |
| Overhead | Higher | Lower | Lower |
| Nested containers | Works | Requires config | Works |
| GPU passthrough | Yes | Limited | Limited |
| Security | Best | Good | Avoid |

**Recommendation:** Use VMs for Docker workloads. LXC adds complexity for marginal resource savings.

## VM Sizing for Docker

### Minimum for Docker host

```
CPU: 2 cores
RAM: 4 GB (2 GB for OS, 2 GB for containers)
Disk: 50 GB (20 GB OS, 30 GB images/volumes)
```

### Per-container overhead

```
Base: ~10 MB RAM per container
Image layers: Shared between containers
Volumes: Depends on data
```

### Sizing formula

```
Total RAM = 2 GB (OS) + sum(container memory limits) + 20% buffer
Total Disk = 20 GB (OS) + images + volumes + 20% buffer
```

## Storage Backend Selection

| Proxmox Storage | Docker Use Case | Performance |
|-----------------|-----------------|-------------|
| local-lvm | General workloads | Good |
| ZFS | Database containers | Better (snapshots) |
| Ceph | HA workloads | Good (distributed) |
| NFS | Shared config/data | Moderate |

### Volume mapping to Proxmox storage

```yaml
# docker-compose.yaml
volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      device: /mnt/storage/mysql  # Map to Proxmox storage mount
      o: bind
```

## Network Considerations

### Bridge mode (default)

Container gets private IP, NAT to VM IP. Good for most workloads.

```yaml
services:
  web:
    ports:
      - "80:80"  # VM_IP:80 -> container:80
```

### Host mode

Container shares VM network stack. Use for network tools or performance.

```yaml
services:
  pihole:
    network_mode: host  # Container uses VM's IPs directly
```

### Macvlan (direct LAN access)

Container gets own IP on Proxmox bridge.

```bash
# On Docker host (VM)
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  lan
```

```yaml
services:
  app:
    networks:
      lan:
        ipv4_address: 192.168.1.50

networks:
  lan:
    external: true
```

**Note:** Requires Proxmox bridge without VLAN tagging on that interface, or pass-through the VLAN-tagged interface to VM.

## Resource Limits

Always set limits to prevent container runaway affecting VM:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## GPU Passthrough

For containers needing GPU (AI/ML, transcoding):

1. **Proxmox:** Pass GPU to VM
   ```
   hostpci0: 0000:01:00.0,pcie=1
   ```

2. **VM:** Install NVIDIA drivers + nvidia-container-toolkit

3. **Compose:**
   ```yaml
   services:
     plex:
       deploy:
         resources:
           reservations:
             devices:
               - driver: nvidia
                 count: 1
                 capabilities: [gpu]
   ```

## Backup Considerations

### What to backup

| Data | Method | Location |
|------|--------|----------|
| VM disk | Proxmox vzdump | Includes everything |
| Docker volumes | docker run --volumes-from | Application-level |
| Compose files | Git | Version control |

### Proxmox backup includes Docker

When backing up the VM with vzdump, all Docker data (images, volumes, containers) is included.

```bash
vzdump <vmid> --mode snapshot --storage backup
```

### Application-consistent backups

For databases, use pre/post scripts:

```bash
# Pre-backup: flush and lock
docker exec mysql mysql -e "FLUSH TABLES WITH READ LOCK;"

# vzdump runs...

# Post-backup: unlock
docker exec mysql mysql -e "UNLOCK TABLES;"
```

## Troubleshooting

### Container can't reach internet

1. Check VM can reach internet: `ping 8.8.8.8`
2. Check Docker DNS: `docker run --rm alpine nslookup google.com`
3. Check iptables forwarding: `sysctl net.ipv4.ip_forward`

### Port not accessible from LAN

1. Check Proxmox firewall allows port
2. Check VM firewall (ufw/iptables)
3. Check container is bound to 0.0.0.0 not 127.0.0.1

### Disk space issues

```bash
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a --volumes  # WARNING: removes all unused data

# Check VM disk
df -h
```

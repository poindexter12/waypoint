# LXC vs Docker Containers

Understanding when to use Proxmox LXC containers vs Docker containers.

## Fundamental Differences

| Aspect | LXC (Proxmox) | Docker |
|--------|---------------|--------|
| Abstraction | System container (full OS) | Application container |
| Init system | systemd, runit, etc. | Single process (PID 1) |
| Management | Proxmox (pct) | Docker daemon |
| Persistence | Stateful by default | Ephemeral by default |
| Updates | apt/yum inside container | Replace container |
| Networking | Proxmox managed | Docker managed |

## When to Use LXC

- **Long-running services** with traditional management (systemd, cron)
- **Multi-process applications** that expect init system
- **Legacy apps** not designed for containers
- **Dev/test environments** mimicking full VMs
- **Resource efficiency** when full VM isolation not needed
- **Direct Proxmox management** (backup, snapshots, migration)

```bash
# Create LXC
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname mycontainer \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --cores 2 \
  --memory 2048 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

## When to Use Docker

- **Microservices** with single responsibility
- **CI/CD pipelines** with reproducible builds
- **Rapid deployment** and scaling
- **Application isolation** within a host
- **Compose stacks** with multi-container apps
- **Ecosystem tooling** (registries, orchestration)

```yaml
# docker-compose.yaml
services:
  app:
    image: myapp:1.0
    restart: unless-stopped
```

## Decision Matrix

| Scenario | Recommendation | Rationale |
|----------|---------------|-----------|
| Pi-hole | Docker on VM | Easy updates, compose ecosystem |
| Database server | LXC or VM | Stateful, traditional management |
| Web app microservice | Docker | Ephemeral, scalable |
| Development environment | LXC | Full OS, multiple services |
| CI runner | Docker on VM | Isolation, reproducibility |
| Network appliance | LXC | Direct network access, systemd |
| Home automation | Docker on VM | Compose stacks, easy backup |

## Hybrid Approach

Common pattern: **VM runs Docker**, managed by Proxmox.

```
Proxmox Node
├── VM: docker-host-1 (template 102)
│   ├── Container: nginx
│   ├── Container: app
│   └── Container: redis
├── VM: docker-host-2 (template 102)
│   ├── Container: postgres
│   └── Container: backup
└── LXC: pihole (direct network)
```

Benefits:
- Proxmox handles VM-level backup/migration
- Docker handles application deployment
- Clear separation of concerns

## Docker in LXC (Not Recommended)

Running Docker inside LXC is possible but adds complexity:

### Requirements

1. Privileged container OR nested containers enabled
2. AppArmor profile modifications
3. Keyctl feature enabled

```bash
# LXC config (Proxmox)
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
features: keyctl=1,nesting=1
```

### Issues

- Security: Reduced isolation
- Compatibility: Some Docker features broken
- Debugging: Two container layers
- Backup: More complex

**Recommendation:** Use VM with Docker instead.

## Resource Comparison

For equivalent workload:

| Resource | VM + Docker | LXC | Docker in LXC |
|----------|-------------|-----|---------------|
| RAM overhead | ~500 MB | ~50 MB | ~100 MB |
| Disk overhead | ~5 GB | ~500 MB | ~1 GB |
| Boot time | 30-60s | 2-5s | 5-10s |
| Isolation | Full | Shared kernel | Shared kernel |
| Complexity | Low | Low | High |

## Migration Paths

### LXC to Docker

1. Export application config from LXC
2. Create Dockerfile/compose
3. Build image
4. Deploy to Docker host
5. Migrate data volumes

### Docker to LXC

1. Install service directly in LXC (apt/yum)
2. Configure with systemd
3. Migrate data
4. Update Proxmox firewall rules

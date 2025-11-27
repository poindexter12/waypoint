# Docker Volumes Reference

## Volume Types

### Named Volumes (Recommended)

Managed by Docker, stored in `/var/lib/docker/volumes/`.

```yaml
volumes:
  db-data:

services:
  db:
    volumes:
      - db-data:/var/lib/mysql
```

Benefits:
- Portable across hosts
- Backup-friendly
- No permission issues
- Can use volume drivers (NFS, etc.)

### Bind Mounts

Direct host path mapping.

```yaml
services:
  web:
    volumes:
      - ./config:/etc/app/config:ro
      - /host/data:/container/data
```

Benefits:
- Direct file access from host
- Development workflow (live reload)
- Access to host files

Drawbacks:
- Host-dependent paths
- Permission issues possible
- Less portable

### tmpfs Mounts

In-memory storage (Linux only).

```yaml
services:
  app:
    tmpfs:
      - /tmp
      - /run:size=100m
```

Benefits:
- Fast (RAM-based)
- Secure (not persisted)
- Good for secrets, cache

## Volume Options

### Read-Only

```yaml
volumes:
  - ./config:/etc/app/config:ro
```

### Bind Propagation

```yaml
volumes:
  - type: bind
    source: ./data
    target: /data
    bind:
      propagation: rslave
```

### Volume Driver Options

```yaml
volumes:
  nfs-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: ":/export/data"
```

## Common Patterns

### Database Data

```yaml
services:
  postgres:
    image: postgres:15
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: secret

volumes:
  pgdata:
```

### Configuration Files

```yaml
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./html:/usr/share/nginx/html:ro
```

### Shared Data Between Services

```yaml
services:
  app:
    volumes:
      - shared:/data

  worker:
    volumes:
      - shared:/data

volumes:
  shared:
```

### Log Persistence

```yaml
services:
  app:
    volumes:
      - logs:/var/log/app

volumes:
  logs:
```

## Backup and Restore

### Backup Named Volume

```bash
# Create backup
docker run --rm \
  -v myvolume:/source:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/myvolume.tar.gz -C /source .

# Restore backup
docker run --rm \
  -v myvolume:/target \
  -v $(pwd):/backup \
  alpine tar xzf /backup/myvolume.tar.gz -C /target
```

### Copy Files from Volume

```bash
docker cp <container>:/path/to/file ./local-file
```

## Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume>

# Remove unused volumes
docker volume prune

# Remove specific volume
docker volume rm <volume>

# Create volume manually
docker volume create --name myvolume
```

## Permissions

### Common Permission Issues

```bash
# Check container user
docker exec <container> id

# Check volume permissions
docker exec <container> ls -la /data
```

### Solutions

```yaml
# Run as specific user
services:
  app:
    user: "1000:1000"
    volumes:
      - ./data:/data
```

Or fix host permissions:
```bash
chown -R 1000:1000 ./data
```

## Best Practices

1. **Use named volumes for data** - More portable than bind mounts
2. **Read-only when possible** - Use `:ro` for config files
3. **Separate concerns** - Different volumes for data, config, logs
4. **Backup strategy** - Plan for volume backup/restore
5. **Don't store in image** - Data should be in volumes, not image layers
6. **Use .dockerignore** - Exclude data directories from build context

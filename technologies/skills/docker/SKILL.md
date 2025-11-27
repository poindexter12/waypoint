---
name: docker
description: |
  Docker and Docker Compose reference for container deployment, networking, volumes,
  and orchestration. Use when working with docker-compose.yaml, Dockerfiles,
  troubleshooting containers, or planning container architecture.
  Triggers: docker, compose, container, dockerfile, volume, network, service.
---

# Docker Skill

Docker and Docker Compose reference for containerized application deployment and management.

## Quick Reference

```bash
# Container operations
docker ps                         # List running containers
docker ps -a                      # List all containers
docker logs <container>           # View logs
docker logs -f <container>        # Follow logs
docker exec -it <container> sh    # Shell into container
docker inspect <container>        # Full container details

# Compose operations
docker compose up -d              # Start services (detached)
docker compose down               # Stop and remove
docker compose ps                 # List compose services
docker compose logs -f            # Follow all logs
docker compose pull               # Pull latest images
docker compose restart            # Restart services

# Troubleshooting
docker stats                      # Resource usage
docker network ls                 # List networks
docker network inspect <net>      # Network details
docker volume ls                  # List volumes
docker system df                  # Disk usage
docker system prune               # Clean up unused resources
```

## Reference Files

Load on-demand based on task:

| Topic | File | When to Load |
|-------|------|--------------|
| Compose Structure | [compose.md](references/compose.md) | Writing docker-compose.yaml |
| Networking | [networking.md](references/networking.md) | Network modes, port mapping |
| Volumes | [volumes.md](references/volumes.md) | Data persistence, mounts |
| Dockerfile | [dockerfile.md](references/dockerfile.md) | Building images |
| Troubleshooting | [troubleshooting.md](references/troubleshooting.md) | Common errors, diagnostics |

## Compose File Quick Reference

```yaml
name: myapp  # Project name (optional)

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    networks:
      - frontend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  frontend:
    driver: bridge

volumes:
  data:
```

## Validation Checklist

Before deploying containers:

- [ ] Services defined with specific image tags (not :latest)
- [ ] Port mappings without conflicts
- [ ] Volumes for persistent data
- [ ] Networks configured appropriately
- [ ] Resource limits set (memory, CPU)
- [ ] Health checks for critical services
- [ ] Restart policy appropriate
- [ ] Secrets not in images or compose file
- [ ] .env file for environment variables

## Network Mode Quick Decision

| Mode | Use Case | Isolation |
|------|----------|-----------|
| bridge | Default, most services | Container isolated |
| host | Performance, network tools | No isolation |
| macvlan | Direct LAN access | Own MAC/IP |
| ipvlan | Like macvlan, shared MAC | Own IP |
| none | No networking | Full isolation |

## Volume Type Quick Decision

| Type | Use Case | Portability |
|------|----------|-------------|
| Named volume | Database, app data | Best |
| Bind mount | Config files, dev | Host-dependent |
| tmpfs | Secrets, cache | Memory only |

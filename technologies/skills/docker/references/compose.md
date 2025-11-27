# Docker Compose Reference

## File Structure

```yaml
name: project-name  # Optional, defaults to directory name

services:
  service-name:
    # Image or build
    image: image:tag
    build:
      context: ./path
      dockerfile: Dockerfile

    # Networking
    ports:
      - "host:container"
    networks:
      - network-name

    # Storage
    volumes:
      - named-volume:/path
      - ./host-path:/container-path

    # Environment
    environment:
      KEY: value
    env_file:
      - .env

    # Dependencies
    depends_on:
      - other-service

    # Lifecycle
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

    # Resources
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          memory: 256M

networks:
  network-name:
    driver: bridge

volumes:
  named-volume:
```

## Service Options

### Image vs Build

```yaml
# Use existing image
image: nginx:1.25-alpine

# Build from Dockerfile
build:
  context: .
  dockerfile: Dockerfile
  args:
    BUILD_ARG: value
```

### Port Mapping

```yaml
ports:
  - "80:80"           # host:container
  - "443:443"
  - "127.0.0.1:8080:80"  # localhost only
  - "8080-8090:8080-8090"  # range
```

### Environment Variables

```yaml
# Inline
environment:
  DATABASE_URL: postgres://db:5432/app
  DEBUG: "false"

# From file
env_file:
  - .env
  - .env.local
```

### Dependencies

```yaml
depends_on:
  - db
  - redis

# With conditions (compose v2.1+)
depends_on:
  db:
    condition: service_healthy
```

### Restart Policies

| Policy | Behavior |
|--------|----------|
| no | Never restart (default) |
| always | Always restart |
| unless-stopped | Restart unless manually stopped |
| on-failure | Restart only on error exit |

### Health Checks

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s      # Time between checks
  timeout: 10s       # Check timeout
  retries: 3         # Failures before unhealthy
  start_period: 40s  # Grace period on startup
```

### Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 256M
```

## Network Configuration

### Custom Network

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

### External Network

```yaml
networks:
  existing-network:
    external: true
```

### Macvlan Network

```yaml
networks:
  lan:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
```

## Volume Configuration

### Named Volume

```yaml
volumes:
  data:
    driver: local

services:
  db:
    volumes:
      - data:/var/lib/mysql
```

### Bind Mount

```yaml
services:
  web:
    volumes:
      - ./config:/etc/app/config:ro
      - ./data:/app/data
```

### tmpfs Mount

```yaml
services:
  app:
    tmpfs:
      - /tmp
      - /run
```

## Multi-Environment Setup

### Using .env Files

```bash
# .env
COMPOSE_PROJECT_NAME=myapp
IMAGE_TAG=latest
```

```yaml
# docker-compose.yaml
services:
  app:
    image: myapp:${IMAGE_TAG}
```

### Override Files

```bash
# Base config
docker-compose.yaml

# Development overrides
docker-compose.override.yaml  # Auto-loaded

# Production
docker compose -f docker-compose.yaml -f docker-compose.prod.yaml up
```

## Useful Commands

```bash
# Start with rebuild
docker compose up -d --build

# Scale service
docker compose up -d --scale web=3

# View config after variable substitution
docker compose config

# Execute command in service
docker compose exec web sh

# View service logs
docker compose logs -f web

# Restart single service
docker compose restart web
```

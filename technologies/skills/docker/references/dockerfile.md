# Dockerfile Reference

## Basic Structure

```dockerfile
# Base image
FROM ubuntu:22.04

# Metadata
LABEL maintainer="team@example.com"
LABEL version="1.0"

# Environment
ENV APP_HOME=/app
WORKDIR $APP_HOME

# Install dependencies
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*

# Copy files
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# Non-root user
RUN useradd -r -s /bin/false appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/health || exit 1

# Entry point
ENTRYPOINT ["python"]
CMD ["app.py"]
```

## Multi-Stage Builds

Reduce final image size by separating build and runtime:

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Runtime stage
FROM alpine:3.18
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

## Common Base Images

| Image | Size | Use Case |
|-------|------|----------|
| alpine | ~5MB | Minimal, production |
| debian:slim | ~80MB | Compatibility |
| ubuntu | ~75MB | Development |
| distroless | ~20MB | Security-focused |
| scratch | 0MB | Static binaries only |

## Instructions Reference

### FROM

```dockerfile
FROM image:tag
FROM image:tag AS builder
FROM --platform=linux/amd64 image:tag
```

### RUN

```dockerfile
# Shell form
RUN apt-get update && apt-get install -y package

# Exec form
RUN ["executable", "param1", "param2"]
```

### COPY vs ADD

```dockerfile
# COPY - preferred for local files
COPY ./src /app/src
COPY --chown=user:group files /app/

# ADD - can extract tars, fetch URLs (use sparingly)
ADD archive.tar.gz /app/
```

### ENV vs ARG

```dockerfile
# ARG - build-time only
ARG VERSION=1.0

# ENV - persists in image
ENV APP_VERSION=$VERSION
```

### EXPOSE

```dockerfile
EXPOSE 8080
EXPOSE 443/tcp
EXPOSE 53/udp
```

Documentation only - doesn't publish ports.

### ENTRYPOINT vs CMD

```dockerfile
# ENTRYPOINT - main executable
ENTRYPOINT ["python"]

# CMD - default arguments (can be overridden)
CMD ["app.py"]

# Combined: python app.py
# Override: docker run image other.py -> python other.py
```

### USER

```dockerfile
RUN useradd -r -s /bin/false appuser
USER appuser
```

### HEALTHCHECK

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
```

## Best Practices

### Layer Caching

Order from least to most frequently changed:

```dockerfile
# Rarely changes - cached
FROM node:18-alpine
WORKDIR /app

# Changes when deps change
COPY package*.json ./
RUN npm install

# Changes frequently - rebuild each time
COPY . .
```

### Reduce Layers

Combine RUN commands:

```dockerfile
# Bad - 3 layers
RUN apt-get update
RUN apt-get install -y package
RUN rm -rf /var/lib/apt/lists/*

# Good - 1 layer
RUN apt-get update && \
    apt-get install -y package && \
    rm -rf /var/lib/apt/lists/*
```

### Security

```dockerfile
# Use specific tags
FROM node:18.17.0-alpine  # Not :latest

# Non-root user
USER nobody

# Read-only filesystem
# (Set at runtime with --read-only)

# No secrets in image
# (Use build args or runtime secrets)
```

### .dockerignore

```
.git
.gitignore
node_modules
*.log
.env
Dockerfile
docker-compose.yaml
README.md
```

## Build Commands

```bash
# Basic build
docker build -t myimage:tag .

# With build args
docker build --build-arg VERSION=1.0 -t myimage .

# No cache
docker build --no-cache -t myimage .

# Specific Dockerfile
docker build -f Dockerfile.prod -t myimage .

# Multi-platform
docker buildx build --platform linux/amd64,linux/arm64 -t myimage .
```

## Debugging Builds

```bash
# Build with progress output
docker build --progress=plain -t myimage .

# Inspect layers
docker history myimage

# Check image size
docker images myimage
```

# Docker Troubleshooting Reference

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Container exits immediately | Bad entrypoint, missing deps | Check logs, verify CMD |
| Port already in use | Conflict with host/other container | `lsof -i :<port>`, change mapping |
| Volume permission denied | UID mismatch | Check ownership, use named volumes |
| Network not found | Network removed/not created | `docker network create` |
| Image pull failed | Registry/auth/name issue | Check registry, credentials, name |
| OOM killed | Exceeded memory limit | Increase limit or optimize app |
| DNS resolution failed | Network config issue | Check DNS settings, network mode |
| Health check failing | App not responding | Check command, increase timeout |

## Diagnostic Commands

### Container Status

```bash
# List all containers (including stopped)
docker ps -a

# Check exit code
docker inspect <container> --format '{{.State.ExitCode}}'

# Check restart count
docker inspect <container> --format '{{.RestartCount}}'
```

### Logs

```bash
# View logs
docker logs <container>

# Follow logs
docker logs -f <container>

# Last N lines
docker logs --tail 100 <container>

# With timestamps
docker logs -t <container>

# Since time
docker logs --since 10m <container>
```

### Resource Usage

```bash
# Real-time stats
docker stats

# Single container
docker stats <container>

# Disk usage
docker system df
docker system df -v  # Verbose
```

### Container Details

```bash
# Full inspection
docker inspect <container>

# Specific fields
docker inspect <container> --format '{{.State.Status}}'
docker inspect <container> --format '{{json .NetworkSettings.Networks}}'
docker inspect <container> --format '{{.Mounts}}'
```

### Process and Network

```bash
# Running processes
docker top <container>

# Execute command
docker exec <container> ps aux
docker exec <container> netstat -tlnp

# Network connectivity
docker exec <container> ping <host>
docker exec <container> curl <url>
docker exec <container> nslookup <hostname>
```

## Troubleshooting Workflows

### Container Won't Start

1. Check logs: `docker logs <container>`
2. Check exit code: `docker inspect <container> --format '{{.State.ExitCode}}'`
3. Run interactively: `docker run -it <image> sh`
4. Check entrypoint/cmd: `docker inspect <image> --format '{{.Config.Cmd}}'`

### Container Keeps Restarting

1. Check logs for errors
2. Verify health check if configured
3. Check resource limits (OOM)
4. Test entrypoint manually

### Network Issues

1. Verify network exists: `docker network ls`
2. Check container attached: `docker inspect <container> --format '{{.NetworkSettings.Networks}}'`
3. Test DNS: `docker exec <container> nslookup <service>`
4. Check port mapping: `docker port <container>`

### Volume Issues

1. Check mount: `docker inspect <container> --format '{{.Mounts}}'`
2. Verify permissions inside: `docker exec <container> ls -la /path`
3. Check host path exists (bind mounts)
4. Try named volume instead

### Performance Issues

1. Check resource usage: `docker stats`
2. Review limits: `docker inspect <container> --format '{{.HostConfig.Memory}}'`
3. Check for resource contention
4. Profile application inside container

## Cleanup

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused
docker system prune -a --volumes
```

## Debugging Compose

```bash
# Validate compose file
docker compose config

# See what would run
docker compose config --services

# Check why service isn't starting
docker compose logs <service>

# Force recreate
docker compose up -d --force-recreate

# Rebuild images
docker compose up -d --build
```

## Common Compose Issues

| Problem | Check |
|---------|-------|
| Service not starting | `docker compose logs <service>` |
| depends_on not working | Service starts but app not ready (use healthcheck) |
| Volume not persisting | Check volume name, not recreated |
| Env vars not loading | Check .env file location, syntax |
| Network errors | Check network names, external networks |

## Health Check Debugging

```bash
# Check health status
docker inspect <container> --format '{{.State.Health.Status}}'

# View health log
docker inspect <container> --format '{{json .State.Health}}' | jq

# Test health command manually
docker exec <container> <health-command>
```

## Emergency Recovery

### Force Stop

```bash
docker kill <container>
```

### Remove Stuck Container

```bash
docker rm -f <container>
```

### Reset Docker

```bash
# Restart Docker daemon
sudo systemctl restart docker

# Or on macOS
# Restart Docker Desktop
```

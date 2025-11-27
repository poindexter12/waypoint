# Docker Networking Reference

## Network Drivers

### Bridge (Default)

Isolated container network with port mapping.

```yaml
networks:
  app-network:
    driver: bridge
```

- Containers get private IPs (172.17.0.0/16 default)
- Port mapping exposes services (`-p 80:80`)
- DNS resolution between containers by name
- Default for single-host deployments

### Host

Container shares host network stack.

```yaml
services:
  app:
    network_mode: host
```

- No network isolation
- No port mapping needed (container uses host ports)
- Best performance (no NAT overhead)
- Use for: Network tools, performance-critical apps

### Macvlan

Container gets own MAC address on physical network.

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
          ip_range: 192.168.1.128/25
```

- Container appears as physical device on LAN
- Direct network access, no port mapping
- Use for: Services needing LAN presence (DNS, DHCP)
- Requires promiscuous mode on parent interface

### IPvlan

Like macvlan but shares host MAC address.

```yaml
networks:
  lan:
    driver: ipvlan
    driver_opts:
      parent: eth0
      ipvlan_mode: l2  # or l3
```

- L2 mode: Same subnet as host
- L3 mode: Different subnet, requires routing
- Use when: Macvlan blocked by switch, cloud environments

### None

No networking.

```yaml
services:
  isolated:
    network_mode: none
```

## Port Mapping

```yaml
ports:
  # Simple mapping
  - "80:80"

  # Different host port
  - "8080:80"

  # Localhost only
  - "127.0.0.1:8080:80"

  # UDP
  - "53:53/udp"

  # Range
  - "8080-8090:8080-8090"

  # Random host port
  - "80"
```

## DNS and Service Discovery

### Automatic DNS

Containers on same network resolve each other by service name:

```yaml
services:
  web:
    networks:
      - app
  db:
    networks:
      - app
```

`web` can reach `db` at hostname `db`.

### Aliases

```yaml
services:
  db:
    networks:
      app:
        aliases:
          - database
          - mysql
```

### Custom DNS

```yaml
services:
  app:
    dns:
      - 8.8.8.8
      - 8.8.4.4
    dns_search:
      - example.com
```

## Network Isolation

### Internal Networks

No external connectivity:

```yaml
networks:
  backend:
    internal: true
```

### Multiple Networks

```yaml
services:
  web:
    networks:
      - frontend
      - backend

  db:
    networks:
      - backend  # Not on frontend

networks:
  frontend:
  backend:
    internal: true
```

## Static IPs

```yaml
services:
  app:
    networks:
      app-network:
        ipv4_address: 172.20.0.10

networks:
  app-network:
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

## Troubleshooting

### Inspect Network

```bash
docker network ls
docker network inspect <network>
```

### Container Network Info

```bash
docker inspect <container> --format '{{json .NetworkSettings.Networks}}'
```

### Test Connectivity

```bash
# From inside container
docker exec <container> ping <target>
docker exec <container> curl <url>

# Check DNS
docker exec <container> nslookup <hostname>
```

### Common Issues

| Problem | Check |
|---------|-------|
| Can't reach container | Port mapping, firewall, network attachment |
| DNS not working | Same network, container running |
| Slow network | Network mode, MTU settings |
| Port already in use | `lsof -i :<port>`, change mapping |

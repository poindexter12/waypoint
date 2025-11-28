# Proxmox Networking Reference

## Linux Bridges

Default networking method for Proxmox VMs and containers.

### Bridge Configuration

```
# /etc/network/interfaces example
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.10/24
    gateway 192.168.1.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
```

### VLAN-Aware Bridge

Enable VLAN tagging at VM level instead of separate bridges:

- Set `bridge-vlan-aware yes` on bridge
- Configure VLAN tag in VM network config
- Simpler management, fewer bridges needed

### Separate Bridges (Alternative)

One bridge per VLAN:

- vmbr0: Untagged/native VLAN
- vmbr1: VLAN 10
- vmbr5: VLAN 5

More bridges but explicit network separation.

## VLAN Configuration

### At VM Level (VLAN-aware bridge)

```
net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr0,tag=20
```

### At Bridge Level (Separate bridges)

```
net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr20
```

## Firewall

Three levels of firewall rules:

| Level | Scope | Use Case |
|-------|-------|----------|
| Datacenter | Cluster-wide | Default policies |
| Node | Per-node | Node-specific rules |
| VM/Container | Per-VM | Application-specific |

### Default Policy

- Input: DROP (only allow explicit rules)
- Output: ACCEPT
- Enable firewall per VM in Options

### Common Rules

```
# Allow SSH
IN ACCEPT -p tcp --dport 22

# Allow HTTP/HTTPS
IN ACCEPT -p tcp --dport 80
IN ACCEPT -p tcp --dport 443

# Allow ICMP (ping)
IN ACCEPT -p icmp
```

## SDN (Software Defined Networking)

Advanced networking for complex multi-tenant setups.

### Zone Types

| Type | Use Case |
|------|----------|
| Simple | Basic L2 network |
| VLAN | VLAN-based isolation |
| VXLAN | Overlay networking |
| EVPN | BGP-based routing |

### When to Use SDN

- Multi-tenant environments
- Complex routing requirements
- Cross-node L2 networks
- VXLAN overlay needs

For homelab: Standard bridges usually sufficient.

## Network Performance

### Jumbo Frames

Enable on storage network for better throughput:

```
# Set MTU 9000 on bridge
auto vmbr40
iface vmbr40 inet static
    mtu 9000
    ...
```

Requires: All devices in path support jumbo frames.

### VirtIO Multiqueue

Enable parallel network processing for high-throughput VMs:

```
net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr0,queues=4
```

## Troubleshooting

### Check Bridge Status

```bash
brctl show              # List bridges and attached interfaces
ip link show vmbr0      # Bridge interface details
bridge vlan show        # VLAN configuration
```

### Check VM Network

```bash
qm config <vmid> | grep net   # VM network config
ip addr                        # From inside VM
```

### Common Issues

| Problem | Check |
|---------|-------|
| No connectivity | Bridge exists, interface attached |
| Wrong VLAN | Tag matches switch config |
| Slow network | MTU mismatch, driver type |
| Firewall blocking | Rules, policy, enabled status |

### Connectivity Diagnostics

```bash
# Basic connectivity
ping -c 3 <host>
traceroute <host>
mtr <host>

# DNS
dig <hostname>
nslookup <hostname>
host <hostname>

# Ports and connections
ss -tlnp                    # Listening TCP ports
ss -tunp                    # All connections
nc -zv <host> <port>        # Test port
telnet <host> <port>        # Interactive port test
```

### Routing Diagnostics

```bash
ip route                    # Full routing table
ip route get <ip>           # Route to specific IP
route -n                    # Numeric routing table
```

### Interface Diagnostics

```bash
ip addr                     # All interface IPs
ip link show                # Interface status
ethtool <interface>         # Interface details/stats
ip -s link                  # Interface statistics
```

### VLAN Verification

```bash
cat /proc/net/vlan/*        # VLAN interfaces
bridge vlan show            # Bridge VLAN config
```

### MTU Check (jumbo frames)

```bash
# Test path MTU (9000 byte frames need 8972 payload)
ping -c 3 -M do -s 8972 <storage-host>
```

### Common Network Errors

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| No route to host | Routing table | Check `ip route`, verify gateway |
| Connection refused | Service not running | Check service, verify port |
| VLAN not working | Tagging issue | Check switch config, VLAN tags |
| MTU mismatch | Jumbo frames | Verify MTU on all devices in path |

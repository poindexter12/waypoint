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

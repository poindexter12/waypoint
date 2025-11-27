# Proxmox Clustering Reference

## Cluster Benefits

- Centralized web management
- Live VM migration between nodes
- High availability (HA) with automatic failover
- Shared configuration

## Cluster Requirements

| Requirement | Details |
|-------------|---------|
| Version | Same major/minor Proxmox version |
| Time | NTP synchronized |
| Network | Low-latency cluster network |
| Names | Unique node hostnames |
| Storage | Shared storage for HA |

## Cluster Commands

```bash
# Check cluster status
pvecm status

# List cluster nodes
pvecm nodes

# Add node to cluster (run on new node)
pvecm add <existing-node>

# Remove node (run on remaining node)
pvecm delnode <node-name>

# Expected votes (split-brain recovery)
pvecm expected <votes>
```

## Quorum

Cluster requires majority of nodes online to operate.

| Nodes | Quorum | Can Lose |
|-------|--------|----------|
| 2 | 2 | 0 (use QDevice) |
| 3 | 2 | 1 |
| 4 | 3 | 1 |
| 5 | 3 | 2 |

### QDevice

External quorum device for even-node clusters:

- Prevents split-brain in 2-node clusters
- Runs on separate machine
- Provides tie-breaking vote

## High Availability (HA)

Automatic VM restart on healthy node if host fails.

### Requirements

- Shared storage (Ceph, NFS, iSCSI)
- Fencing enabled (watchdog)
- HA group configured
- VM added to HA

### HA States

| State | Description |
|-------|-------------|
| started | VM running, managed by HA |
| stopped | VM stopped intentionally |
| migrate | Migration in progress |
| relocate | Moving to different node |
| error | Problem detected |

### HA Configuration

1. Enable fencing (watchdog device)
2. Create HA group (optional)
3. Add VM to HA: Datacenter → HA → Add

### Fencing

Prevents split-brain by forcing failed node to stop:

```bash
# Check watchdog status
cat /proc/sys/kernel/watchdog

# Watchdog config
/etc/pve/ha/fence.cfg
```

## Live Migration

Move running VM between nodes without downtime.

### Requirements

- Shared storage OR local-to-local migration
- Same CPU architecture
- Network connectivity
- Sufficient resources on target

### Migration Types

| Type | Downtime | Requirements |
|------|----------|--------------|
| Live | Minimal | Shared storage |
| Offline | Full | Any storage |
| Local storage | Moderate | Copies disk |

### Migration Command

```bash
# Live migrate
qm migrate <vmid> <target-node>

# Offline migrate
qm migrate <vmid> <target-node> --offline

# With local disk
qm migrate <vmid> <target-node> --with-local-disks
```

## Cluster Network

### Corosync Network

Cluster communication (default port 5405):

- Low-latency required
- Dedicated VLAN recommended
- Redundant links for HA

### Configuration

```
# /etc/pve/corosync.conf
nodelist {
  node {
    name: node1
    ring0_addr: 192.168.10.1
  }
  node {
    name: node2
    ring0_addr: 192.168.10.2
  }
}
```

## Troubleshooting

### Quorum Lost

```bash
# Check status
pvecm status

# Force expected votes (DANGEROUS)
pvecm expected 1

# Then: recover remaining nodes
```

### Node Won't Join

- Check network connectivity
- Verify time sync
- Check Proxmox versions match
- Review /var/log/pve-cluster/

### Split Brain Recovery

1. Identify authoritative node
2. Stop cluster services on other nodes
3. Set expected votes
4. Restart and rejoin nodes

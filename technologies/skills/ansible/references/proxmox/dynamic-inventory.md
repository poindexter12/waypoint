# Ansible Proxmox Dynamic Inventory

Query Proxmox API for automatic inventory generation.

## Plugin Setup

### Requirements

```bash
pip install proxmoxer requests
ansible-galaxy collection install community.general
```

### Inventory File

Create `inventory/proxmox.yml`:

```yaml
plugin: community.general.proxmox
url: https://proxmox.example.com:8006
user: ansible@pve
token_id: mytoken
token_secret: "{{ lookup('env', 'PROXMOX_TOKEN_SECRET') }}"
validate_certs: false

# Include VMs and containers
want_facts: true
want_proxmox_nodes_ansible_host: false

# Filter by status
filters:
  - status == "running"

# Group by various attributes
groups:
  # By Proxmox node
  node_joseph: proxmox_node == "joseph"
  node_maxwell: proxmox_node == "maxwell"
  node_everette: proxmox_node == "everette"

  # By type
  vms: proxmox_type == "qemu"
  containers: proxmox_type == "lxc"

  # By template naming convention
  docker_hosts: "'docker' in proxmox_name"
  pihole: "'pihole' in proxmox_name"

# Host variables from Proxmox
compose:
  ansible_host: proxmox_agent_interfaces[0].ip-addresses[0].ip-address | default(proxmox_name)
  ansible_user: "'ubuntu'"
  proxmox_vmid: proxmox_vmid
  proxmox_node: proxmox_node
```

### Enable in ansible.cfg

```ini
[inventory]
enable_plugins = community.general.proxmox, yaml, ini
```

## Testing Inventory

```bash
# List all hosts
ansible-inventory -i inventory/proxmox.yml --list

# Graph view
ansible-inventory -i inventory/proxmox.yml --graph

# Specific host details
ansible-inventory -i inventory/proxmox.yml --host myvm
```

## Common Patterns

### Filter by Tags

Proxmox 7+ supports VM tags:

```yaml
groups:
  webservers: "'web' in proxmox_tags"
  databases: "'db' in proxmox_tags"
  production: "'prod' in proxmox_tags"
```

### Filter by VMID Range

```yaml
filters:
  - vmid >= 200
  - vmid < 300

groups:
  dev_vms: proxmox_vmid >= 200 and proxmox_vmid < 300
  prod_vms: proxmox_vmid >= 300 and proxmox_vmid < 400
```

### IP Address from QEMU Agent

Requires QEMU guest agent running in VM:

```yaml
compose:
  # Primary IP from agent
  ansible_host: >-
    proxmox_agent_interfaces
    | selectattr('name', 'equalto', 'eth0')
    | map(attribute='ip-addresses')
    | flatten
    | selectattr('ip-address-type', 'equalto', 'ipv4')
    | map(attribute='ip-address')
    | first
    | default(proxmox_name)
```

### Static + Dynamic Inventory

Combine with static inventory:

```bash
# inventory/
#   static.yml      # Static hosts
#   proxmox.yml     # Dynamic from Proxmox

ansible-playbook -i inventory/ playbook.yml
```

## Available Variables

Variables populated from Proxmox API:

| Variable | Description |
|----------|-------------|
| proxmox_vmid | VM/container ID |
| proxmox_name | VM/container name |
| proxmox_type | "qemu" or "lxc" |
| proxmox_status | running, stopped, etc. |
| proxmox_node | Proxmox node name |
| proxmox_pool | Resource pool (if any) |
| proxmox_tags | Tags (Proxmox 7+) |
| proxmox_template | Is template (bool) |
| proxmox_agent | QEMU agent enabled (bool) |
| proxmox_agent_interfaces | Network info from agent |
| proxmox_cpus | CPU count |
| proxmox_maxmem | Max memory bytes |
| proxmox_maxdisk | Max disk bytes |

## Caching

Enable caching for faster inventory:

```yaml
plugin: community.general.proxmox
# ... auth ...

cache: true
cache_plugin: jsonfile
cache_connection: /tmp/ansible_proxmox_cache
cache_timeout: 300  # 5 minutes
```

Clear cache:
```bash
rm -rf /tmp/ansible_proxmox_cache
```

## Troubleshooting

### No hosts returned

1. Check API connectivity:
   ```bash
   curl -k "https://proxmox:8006/api2/json/cluster/resources" \
     -H "Authorization: PVEAPIToken=ansible@pve!mytoken=secret"
   ```

2. Check filters aren't too restrictive - try removing them

3. Verify token permissions include `VM.Audit`

### QEMU agent data missing

- Agent must be installed and running in guest
- `want_facts: true` must be set
- May take a few seconds after VM boot

### Slow inventory queries

- Enable caching (see above)
- Use filters to reduce results
- Avoid `want_facts: true` if not needed

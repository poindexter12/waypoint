# Ansible Proxmox Gotchas

Common issues when using Ansible with Proxmox VE.

## 1. Token ID Format

**Wrong:**
```yaml
api_token_id: mytoken
```

**Correct:**
```yaml
api_token_id: mytoken  # Just the token name, NOT user@realm!tokenname
```

The module combines `api_user` and `api_token_id` internally.

## 2. VMID Required for Most Operations

Unlike Terraform, you must always specify `vmid`:

```yaml
# Won't auto-generate VMID
- name: Create VM
  community.general.proxmox_kvm:
    # ... auth ...
    vmid: 300  # REQUIRED - no auto-assignment
    name: myvm
```

To find next available VMID:
```yaml
- name: Get cluster resources
  ansible.builtin.uri:
    url: "https://{{ proxmox_api_host }}:8006/api2/json/cluster/resources"
    headers:
      Authorization: "PVEAPIToken={{ proxmox_api_user }}!{{ proxmox_api_token_id }}={{ proxmox_api_token_secret }}"
    validate_certs: false
  register: resources

- name: Calculate next VMID
  ansible.builtin.set_fact:
    next_vmid: "{{ (resources.json.data | selectattr('vmid', 'defined') | map(attribute='vmid') | max) + 1 }}"
```

## 3. Node Parameter Required

Must specify which node to operate on:

```yaml
- name: Create VM
  community.general.proxmox_kvm:
    # ... auth ...
    node: joseph  # REQUIRED - which Proxmox node
    vmid: 300
```

## 4. Clone vs Create

Cloning requires different parameters than creating:

```yaml
# CLONE from template
- name: Clone VM
  community.general.proxmox_kvm:
    # ... auth ...
    node: joseph
    vmid: 300
    name: myvm
    clone: tmpl-ubuntu-2404-standard  # Template name or VMID
    full: true

# CREATE new (less common)
- name: Create VM
  community.general.proxmox_kvm:
    # ... auth ...
    node: joseph
    vmid: 300
    name: myvm
    ostype: l26
    scsihw: virtio-scsi-pci
    bootdisk: scsi0
    scsi:
      scsi0: 'local-lvm:32,format=raw'
```

## 5. Async Operations

Large operations (clone, snapshot) can timeout. Use async:

```yaml
- name: Clone large VM
  community.general.proxmox_kvm:
    # ... auth ...
    clone: large-template
    vmid: 300
    timeout: 600  # Module timeout
  async: 900      # Ansible async timeout
  poll: 10        # Check every 10 seconds
```

## 6. State Idempotency

`state: present` doesn't update existing VMs:

```yaml
# This WON'T change cores on existing VM
- name: Create/update VM
  community.general.proxmox_kvm:
    # ... auth ...
    vmid: 300
    cores: 4      # Ignored if VM exists
    state: present
```

To modify existing VMs, use `proxmox_kvm` with `update: true` (Ansible 2.14+) or use the API directly.

## 7. Network Interface Format (LXC)

LXC containers use a specific JSON-like string format:

```yaml
# WRONG
netif:
  net0:
    bridge: vmbr0
    ip: dhcp

# CORRECT
netif: '{"net0":"name=eth0,bridge=vmbr0,ip=dhcp"}'

# Multiple interfaces
netif: '{"net0":"name=eth0,bridge=vmbr0,ip=dhcp","net1":"name=eth1,bridge=vmbr12,ip=dhcp"}'
```

## 8. Disk Resize Only Grows

`proxmox_disk` resize only increases size:

```yaml
# This adds 20G to current size
- name: Grow disk
  community.general.proxmox_disk:
    # ... auth ...
    vmid: 300
    disk: scsi0
    size: +20G     # Relative increase
    state: resized

# NOT possible to shrink
```

## 9. Template vs VM States

Templates don't support all states:

```yaml
# Can't start a template
- name: Start template
  community.general.proxmox_kvm:
    vmid: 100
    state: started  # FAILS - templates can't run
```

Convert template to VM first if needed.

## 10. Collection Version Matters

Module parameters change between versions. Check installed version:

```bash
ansible-galaxy collection list | grep community.general
```

Update if needed:
```bash
ansible-galaxy collection install community.general --upgrade
```

## 11. Cloud-Init Not Supported

Unlike Terraform's Proxmox provider, the Ansible modules have limited cloud-init support. For cloud-init VMs:

1. Clone template with cloud-init already configured
2. Use API calls to set cloud-init parameters
3. Or configure post-boot with Ansible

```yaml
# Workaround: Use URI module for cloud-init config
- name: Set cloud-init IP
  ansible.builtin.uri:
    url: "https://{{ proxmox_api_host }}:8006/api2/json/nodes/{{ node }}/qemu/{{ vmid }}/config"
    method: PUT
    headers:
      Authorization: "PVEAPIToken={{ proxmox_api_user }}!{{ proxmox_api_token_id }}={{ proxmox_api_token_secret }}"
    body_format: form-urlencoded
    body:
      ipconfig0: "ip=192.168.1.100/24,gw=192.168.1.1"
      ciuser: ubuntu
    validate_certs: false
```

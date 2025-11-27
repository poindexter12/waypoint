# Ansible Proxmox Modules

Proxmox VE management via `community.general` collection.

## Collection Setup

```bash
ansible-galaxy collection install community.general
```

## Core Modules

### proxmox (LXC Containers)

```yaml
- name: Create LXC container
  community.general.proxmox:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    node: joseph
    vmid: 200
    hostname: mycontainer
    ostemplate: local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst
    storage: local-lvm
    cores: 2
    memory: 2048
    disk: 10
    netif: '{"net0":"name=eth0,bridge=vmbr0,ip=dhcp"}'
    state: present

- name: Start container
  community.general.proxmox:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    node: joseph
    vmid: 200
    state: started

- name: Stop container
  community.general.proxmox:
    # ... auth params ...
    vmid: 200
    state: stopped
    force: true  # Force stop if graceful fails

- name: Remove container
  community.general.proxmox:
    # ... auth params ...
    vmid: 200
    state: absent
```

### proxmox_kvm (VMs)

```yaml
- name: Create VM from template
  community.general.proxmox_kvm:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    node: joseph
    vmid: 300
    name: myvm
    clone: tmpl-ubuntu-2404-standard
    full: true  # Full clone (not linked)
    storage: local-lvm
    format: raw
    timeout: 500

- name: Start VM
  community.general.proxmox_kvm:
    # ... auth params ...
    node: joseph
    vmid: 300
    state: started

- name: Stop VM (ACPI shutdown)
  community.general.proxmox_kvm:
    # ... auth params ...
    vmid: 300
    state: stopped
    force: false  # Graceful ACPI

- name: Force stop VM
  community.general.proxmox_kvm:
    # ... auth params ...
    vmid: 300
    state: stopped
    force: true

- name: Current state (running/stopped/present/absent)
  community.general.proxmox_kvm:
    # ... auth params ...
    vmid: 300
    state: current
  register: vm_state
```

### proxmox_template

```yaml
- name: Convert VM to template
  community.general.proxmox_template:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    node: joseph
    vmid: 100
    state: present  # Convert to template

- name: Delete template
  community.general.proxmox_template:
    # ... auth params ...
    vmid: 100
    state: absent
```

### proxmox_snap

```yaml
- name: Create snapshot
  community.general.proxmox_snap:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    vmid: 300
    snapname: before-upgrade
    description: "Snapshot before major upgrade"
    vmstate: false  # Don't include RAM
    state: present

- name: Rollback to snapshot
  community.general.proxmox_snap:
    # ... auth params ...
    vmid: 300
    snapname: before-upgrade
    state: rollback

- name: Remove snapshot
  community.general.proxmox_snap:
    # ... auth params ...
    vmid: 300
    snapname: before-upgrade
    state: absent
```

### proxmox_nic

```yaml
- name: Add NIC to VM
  community.general.proxmox_nic:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    vmid: 300
    interface: net1
    bridge: vmbr12
    model: virtio
    tag: 12  # VLAN tag
    state: present

- name: Remove NIC
  community.general.proxmox_nic:
    # ... auth params ...
    vmid: 300
    interface: net1
    state: absent
```

### proxmox_disk

```yaml
- name: Add disk to VM
  community.general.proxmox_disk:
    api_host: proxmox.example.com
    api_user: ansible@pve
    api_token_id: mytoken
    api_token_secret: "{{ proxmox_token_secret }}"
    vmid: 300
    disk: scsi1
    storage: local-lvm
    size: 50G
    format: raw
    state: present

- name: Resize disk
  community.general.proxmox_disk:
    # ... auth params ...
    vmid: 300
    disk: scsi0
    size: +20G  # Increase by 20G
    state: resized

- name: Detach disk
  community.general.proxmox_disk:
    # ... auth params ...
    vmid: 300
    disk: scsi1
    state: absent
```

## State Reference

| Module | States |
|--------|--------|
| proxmox (LXC) | present, started, stopped, restarted, absent |
| proxmox_kvm | present, started, stopped, restarted, absent, current |
| proxmox_template | present, absent |
| proxmox_snap | present, absent, rollback |
| proxmox_nic | present, absent |
| proxmox_disk | present, absent, resized |

## Common Parameters

All modules share these authentication parameters:

| Parameter | Description |
|-----------|-------------|
| api_host | Proxmox hostname/IP |
| api_user | User (format: user@realm) |
| api_token_id | API token name |
| api_token_secret | API token value |
| validate_certs | Verify TLS (default: true) |
| timeout | API timeout seconds |

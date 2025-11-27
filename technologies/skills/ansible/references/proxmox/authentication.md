# Ansible Proxmox Authentication

## API Token Setup

Create a dedicated Ansible user and API token on Proxmox:

```bash
# On Proxmox node
pveum user add ansible@pve
pveum aclmod / -user ansible@pve -role PVEAdmin
pveum user token add ansible@pve mytoken --privsep 0
```

**Note:** `--privsep 0` gives the token the same permissions as the user.

## Playbook Variables

### Direct in playbook (NOT recommended)

```yaml
vars:
  proxmox_api_host: proxmox.example.com
  proxmox_api_user: ansible@pve
  proxmox_api_token_id: mytoken
  proxmox_api_token_secret: "{{ vault_proxmox_token }}"
```

### Group vars with vault

```yaml
# group_vars/all.yml
proxmox_api_host: proxmox.example.com
proxmox_api_user: ansible@pve
proxmox_api_token_id: mytoken

# group_vars/secrets.yml (ansible-vault encrypted)
proxmox_api_token_secret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Environment variables

```bash
export PROXMOX_HOST=proxmox.example.com
export PROXMOX_USER=ansible@pve
export PROXMOX_TOKEN_ID=mytoken
export PROXMOX_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

```yaml
# In playbook
vars:
  proxmox_api_host: "{{ lookup('env', 'PROXMOX_HOST') }}"
  proxmox_api_user: "{{ lookup('env', 'PROXMOX_USER') }}"
  proxmox_api_token_id: "{{ lookup('env', 'PROXMOX_TOKEN_ID') }}"
  proxmox_api_token_secret: "{{ lookup('env', 'PROXMOX_TOKEN_SECRET') }}"
```

## Reusable Auth Block

Define once, reuse across tasks:

```yaml
vars:
  proxmox_auth: &proxmox_auth
    api_host: "{{ proxmox_api_host }}"
    api_user: "{{ proxmox_api_user }}"
    api_token_id: "{{ proxmox_api_token_id }}"
    api_token_secret: "{{ proxmox_api_token_secret }}"
    validate_certs: false  # For self-signed certs

tasks:
  - name: Create VM
    community.general.proxmox_kvm:
      <<: *proxmox_auth
      node: joseph
      vmid: 300
      name: myvm
      state: present

  - name: Start VM
    community.general.proxmox_kvm:
      <<: *proxmox_auth
      vmid: 300
      state: started
```

## TLS Certificate Handling

### Self-signed certificates

```yaml
community.general.proxmox_kvm:
  # ... auth params ...
  validate_certs: false
```

### Custom CA

```bash
export SSL_CERT_FILE=/path/to/ca-bundle.crt
```

Or in ansible.cfg:

```ini
[defaults]
# For urllib3/requests
ca_cert = /path/to/ca-bundle.crt
```

## Minimum Required Permissions

For full VM/container management:

| Permission | Path | Purpose |
|------------|------|---------|
| VM.Allocate | / | Create VMs |
| VM.Clone | / | Clone templates |
| VM.Config.* | / | Modify VM config |
| VM.PowerMgmt | / | Start/stop VMs |
| VM.Snapshot | / | Create snapshots |
| Datastore.AllocateSpace | / | Allocate disk space |
| Datastore.Audit | / | List storage |

Or use the built-in `PVEAdmin` role for full access.

## Troubleshooting Auth Issues

```yaml
# Debug task to test connection
- name: Test Proxmox API connection
  community.general.proxmox_kvm:
    api_host: "{{ proxmox_api_host }}"
    api_user: "{{ proxmox_api_user }}"
    api_token_id: "{{ proxmox_api_token_id }}"
    api_token_secret: "{{ proxmox_api_token_secret }}"
    validate_certs: false
    vmid: 100
    state: current
  register: result
  ignore_errors: true

- name: Show result
  ansible.builtin.debug:
    var: result
```

Common errors:

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | Bad token | Verify token ID format: `user@realm!tokenname` |
| 403 Forbidden | Insufficient permissions | Check user ACLs with `pveum user permissions ansible@pve` |
| SSL certificate problem | Self-signed cert | Set `validate_certs: false` |
| Connection refused | Wrong host/port | Verify API URL (port 8006) |

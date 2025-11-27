# Ansible Inventory Reference

## YAML Inventory Format

```yaml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
        web2:
          ansible_host: 192.168.1.11
      vars:
        http_port: 80

    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
          db_port: 5432
        db2:
          ansible_host: 192.168.1.21

    production:
      children:
        webservers:
        databases:

  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

## INI Inventory Format

```ini
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[webservers:vars]
http_port=80

[databases]
db1 ansible_host=192.168.1.20 db_port=5432
db2 ansible_host=192.168.1.21

[production:children]
webservers
databases

[all:vars]
ansible_user=ubuntu
```

## Host Variables

Common host variables:

| Variable | Purpose |
|----------|---------|
| `ansible_host` | IP or hostname to connect |
| `ansible_port` | SSH port (default: 22) |
| `ansible_user` | SSH username |
| `ansible_ssh_private_key_file` | SSH key path |
| `ansible_become` | Enable sudo |
| `ansible_become_user` | Sudo target user |
| `ansible_python_interpreter` | Python path |

## Group Variables

```yaml
# group_vars/webservers.yml
http_port: 80
document_root: /var/www/html

# group_vars/all.yml
ntp_server: time.example.com
dns_servers:
  - 8.8.8.8
  - 8.8.4.4
```

## Host Variables Files

```yaml
# host_vars/web1.yml
site_name: production-web1
ssl_cert_path: /etc/ssl/certs/web1.crt
```

## Dynamic Groups

```yaml
# In playbook
- hosts: "{{ target_group | default('all') }}"
```

Run with:
```bash
ansible-playbook playbook.yml -e "target_group=webservers"
```

## Patterns

```bash
# All hosts
ansible all -m ping

# Single host
ansible web1 -m ping

# Group
ansible webservers -m ping

# Multiple groups
ansible 'webservers:databases' -m ping

# Intersection (AND)
ansible 'webservers:&production' -m ping

# Exclusion
ansible 'webservers:!web1' -m ping

# Regex
ansible '~web[0-9]+' -m ping
```

## Limit

```bash
# Limit to specific hosts
ansible-playbook playbook.yml -l web1
ansible-playbook playbook.yml --limit web1,web2
ansible-playbook playbook.yml --limit 'webservers:!web3'
```

## Inventory Check

```bash
# List hosts
ansible-inventory --list
ansible-inventory --graph

# Host info
ansible-inventory --host web1

# Validate
ansible all --list-hosts
```

## Multiple Inventories

```bash
# Multiple files
ansible-playbook -i inventory/production -i inventory/staging playbook.yml

# Directory of inventories
ansible-playbook -i inventory/ playbook.yml
```

## Special Groups

| Group | Contains |
|-------|----------|
| `all` | All hosts |
| `ungrouped` | Hosts not in any group |

## Local Connection

```yaml
localhost:
  ansible_host: 127.0.0.1
  ansible_connection: local
```

Or in inventory:
```ini
localhost ansible_connection=local
```

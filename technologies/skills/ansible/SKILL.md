---
name: ansible
description: |
  Ansible automation reference for playbooks, roles, inventory, variables, and modules.
  Use when writing playbooks, troubleshooting Ansible runs, or designing automation workflows.
  Triggers: ansible, playbook, inventory, role, task, handler, vars, jinja2, galaxy.
---

# Ansible Skill

Ansible automation reference for configuration management and application deployment.

## Quick Reference

```bash
# Test connectivity
ansible all -m ping
ansible <group> -m ping

# Run playbook
ansible-playbook playbook.yml
ansible-playbook playbook.yml -l <host>    # Limit to host
ansible-playbook playbook.yml --check      # Dry-run
ansible-playbook playbook.yml -vvv         # Verbose

# Tags
ansible-playbook playbook.yml --tags "deploy"
ansible-playbook playbook.yml --skip-tags "backup"
ansible-playbook playbook.yml --list-tags

# Variables
ansible-playbook playbook.yml -e "var=value"
ansible-playbook playbook.yml -e "@vars.yml"

# Ad-hoc commands
ansible <group> -m shell -a "command"
ansible <group> -m copy -a "src=file dest=/path"
ansible <group> -m apt -a "name=package state=present"

# Galaxy
ansible-galaxy collection install -r requirements.yml
ansible-galaxy role install <role>
```

## Reference Files

Load on-demand based on task:

| Topic | File | When to Load |
|-------|------|--------------|
| Playbook Structure | [playbooks.md](references/playbooks.md) | Writing playbooks |
| Inventory | [inventory.md](references/inventory.md) | Host/group configuration |
| Variables | [variables.md](references/variables.md) | Variable precedence, facts |
| Modules | [modules.md](references/modules.md) | Common module reference |
| Troubleshooting | [troubleshooting.md](references/troubleshooting.md) | Common errors, debugging |

## Playbook Quick Reference

```yaml
---
- name: Deploy application
  hosts: webservers
  become: true
  vars:
    app_port: 8080

  pre_tasks:
    - name: Validate requirements
      ansible.builtin.assert:
        that:
          - app_secret is defined

  tasks:
    - name: Install packages
      ansible.builtin.apt:
        name: "{{ item }}"
        state: present
      loop:
        - nginx
        - python3

    - name: Deploy config
      ansible.builtin.template:
        src: app.conf.j2
        dest: /etc/app/app.conf
      notify: Restart app

  handlers:
    - name: Restart app
      ansible.builtin.service:
        name: app
        state: restarted

  post_tasks:
    - name: Verify deployment
      ansible.builtin.uri:
        url: "http://localhost:{{ app_port }}/health"
```

## Variable Precedence (High to Low)

1. Extra vars (`-e "var=value"`)
2. Task vars
3. Block vars
4. Role/include vars
5. Play vars
6. Host facts
7. host_vars/
8. group_vars/
9. Role defaults

## Directory Structure

```text
ansible/
├── ansible.cfg          # Configuration
├── inventory/
│   └── hosts.yml        # Inventory
├── group_vars/
│   ├── all.yml          # All hosts
│   └── webservers.yml   # Group-specific
├── host_vars/
│   └── server1.yml      # Host-specific
├── roles/
│   └── app/
│       ├── tasks/
│       ├── handlers/
│       ├── templates/
│       ├── files/
│       └── defaults/
├── playbooks/
│   └── deploy.yml
├── templates/
│   └── config.j2
└── requirements.yml     # Galaxy dependencies
```

## Idempotency Checklist

- [ ] Tasks produce same result on repeated runs
- [ ] No `changed_when: true` unless necessary
- [ ] Use `state: present/absent` not `shell` commands
- [ ] Check mode (`--check`) shows accurate changes
- [ ] Second run shows all "ok" (no changes)

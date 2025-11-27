# Ansible Variables Reference

## Variable Precedence (High to Low)

1. **Extra vars** (`-e "var=value"`)
2. **Task vars** (in task)
3. **Block vars** (in block)
4. **Role/include vars**
5. **set_facts / registered vars**
6. **Play vars_files**
7. **Play vars_prompt**
8. **Play vars**
9. **Host facts**
10. **Playbook host_vars/**
11. **Inventory host_vars/**
12. **Playbook group_vars/**
13. **Inventory group_vars/**
14. **Playbook group_vars/all**
15. **Inventory group_vars/all**
16. **Role defaults**

## Defining Variables

### In Playbook

```yaml
- hosts: all
  vars:
    app_name: myapp
    app_port: 8080

  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
```

### In Tasks

```yaml
- name: Set variable
  ansible.builtin.set_fact:
    my_var: "value"

- name: Register output
  ansible.builtin.command: whoami
  register: user_result

- name: Use registered
  ansible.builtin.debug:
    msg: "User: {{ user_result.stdout }}"
```

### In Roles

```yaml
# roles/app/defaults/main.yml (low priority)
app_port: 8080

# roles/app/vars/main.yml (high priority)
internal_setting: value
```

## Variable Types

```yaml
# String
name: "value"

# Number
port: 8080

# Boolean
enabled: true

# List
packages:
  - nginx
  - python3

# Dictionary
user:
  name: admin
  groups:
    - wheel
    - docker
```

## Accessing Variables

```yaml
# Simple
msg: "{{ my_var }}"

# Dictionary
msg: "{{ user.name }}"
msg: "{{ user['name'] }}"

# List
msg: "{{ packages[0] }}"
msg: "{{ packages | first }}"

# Default value
msg: "{{ my_var | default('fallback') }}"

# Required (fail if undefined)
msg: "{{ my_var }}"  # Fails if undefined
```

## Jinja2 Filters

```yaml
# Default
value: "{{ var | default('default') }}"

# Mandatory
value: "{{ var | mandatory }}"

# Type conversion
port: "{{ port_string | int }}"
flag: "{{ flag_string | bool }}"

# String operations
upper: "{{ name | upper }}"
lower: "{{ name | lower }}"
title: "{{ name | title }}"

# Lists
first: "{{ list | first }}"
last: "{{ list | last }}"
length: "{{ list | length }}"
joined: "{{ list | join(',') }}"

# JSON
json_str: "{{ dict | to_json }}"
yaml_str: "{{ dict | to_yaml }}"

# Path operations
basename: "{{ path | basename }}"
dirname: "{{ path | dirname }}"
```

## Facts

```yaml
# Accessing facts
os: "{{ ansible_distribution }}"
version: "{{ ansible_distribution_version }}"
ip: "{{ ansible_default_ipv4.address }}"
hostname: "{{ ansible_hostname }}"
memory_mb: "{{ ansible_memtotal_mb }}"
cpus: "{{ ansible_processor_vcpus }}"
```

### Gathering Facts

```yaml
- hosts: all
  gather_facts: true  # Default

# Or manually
- name: Gather facts
  ansible.builtin.setup:
    filter: ansible_*

# Specific facts
- name: Get network facts
  ansible.builtin.setup:
    gather_subset:
      - network
```

## Environment Variables

```yaml
# Lookup
value: "{{ lookup('env', 'MY_VAR') }}"

# Set for task
- name: Run with env
  ansible.builtin.command: /bin/command
  environment:
    MY_VAR: "{{ my_value }}"
```

## Secrets/Vault

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Encrypt existing file
ansible-vault encrypt vars.yml

# Run with vault password
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

## Prompt for Variables

```yaml
- hosts: all
  vars_prompt:
    - name: password
      prompt: "Enter password"
      private: true

    - name: environment
      prompt: "Which environment?"
      default: "staging"
```

## Conditionals with Variables

```yaml
- name: Check defined
  when: my_var is defined

- name: Check undefined
  when: my_var is not defined

- name: Check truthy
  when: my_var | bool

- name: Check falsy
  when: not my_var | bool

- name: Check in list
  when: item in my_list

- name: Version comparison
  when: version is version('2.0', '>=')
```

## Hostvars

Access variables from other hosts:

```yaml
- name: Get from other host
  ansible.builtin.debug:
    msg: "{{ hostvars['web1']['ansible_host'] }}"
```

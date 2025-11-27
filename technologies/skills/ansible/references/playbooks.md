# Ansible Playbook Reference

## Basic Structure

```yaml
---
- name: Playbook description
  hosts: target_group
  become: true                    # Run as root
  gather_facts: true              # Collect system info

  vars:
    my_var: value

  vars_files:
    - vars/secrets.yml

  pre_tasks:
    - name: Pre-task
      ansible.builtin.debug:
        msg: "Running before main tasks"

  roles:
    - role_name

  tasks:
    - name: Main task
      ansible.builtin.debug:
        msg: "Main task"

  handlers:
    - name: Handler name
      ansible.builtin.service:
        name: service
        state: restarted

  post_tasks:
    - name: Post-task
      ansible.builtin.debug:
        msg: "Running after main tasks"
```

## Task Options

```yaml
tasks:
  - name: Task with common options
    ansible.builtin.command: /bin/command
    become: true                  # Privilege escalation
    become_user: www-data         # Run as specific user
    when: condition               # Conditional execution
    register: result              # Store output
    ignore_errors: true           # Continue on failure
    changed_when: false           # Override change detection
    failed_when: result.rc != 0   # Custom failure condition
    tags:
      - deploy
      - config
    notify: Handler name          # Trigger handler
```

## Loops

```yaml
# Simple loop
- name: Install packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - python3

# Loop with dict
- name: Create users
  ansible.builtin.user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
  loop:
    - { name: 'user1', groups: 'admin' }
    - { name: 'user2', groups: 'users' }

# Loop over dict
- name: Process items
  ansible.builtin.debug:
    msg: "{{ item.key }}: {{ item.value }}"
  loop: "{{ my_dict | dict2items }}"

# Loop with index
- name: With index
  ansible.builtin.debug:
    msg: "{{ index }}: {{ item }}"
  loop: "{{ my_list }}"
  loop_control:
    index_var: index
```

## Conditionals

```yaml
# Simple when
- name: Only on Ubuntu
  ansible.builtin.apt:
    name: package
  when: ansible_distribution == "Ubuntu"

# Multiple conditions
- name: Complex condition
  ansible.builtin.command: /bin/something
  when:
    - ansible_os_family == "Debian"
    - ansible_distribution_version is version('20.04', '>=')

# Or conditions
- name: Or condition
  ansible.builtin.command: /bin/something
  when: condition1 or condition2

# Check variable
- name: If defined
  ansible.builtin.debug:
    msg: "{{ my_var }}"
  when: my_var is defined
```

## Blocks

```yaml
- name: Block example
  block:
    - name: Task 1
      ansible.builtin.command: /bin/task1

    - name: Task 2
      ansible.builtin.command: /bin/task2

  rescue:
    - name: Handle failure
      ansible.builtin.debug:
        msg: "Block failed"

  always:
    - name: Always run
      ansible.builtin.debug:
        msg: "Cleanup"
```

## Handlers

```yaml
tasks:
  - name: Update config
    ansible.builtin.template:
      src: config.j2
      dest: /etc/app/config
    notify:
      - Restart service
      - Reload config

handlers:
  - name: Restart service
    ansible.builtin.service:
      name: app
      state: restarted

  - name: Reload config
    ansible.builtin.service:
      name: app
      state: reloaded
```

Handlers run once at end of play, even if notified multiple times.

## Including Tasks

```yaml
# Include tasks file
- name: Include tasks
  ansible.builtin.include_tasks: tasks/setup.yml

# Import tasks (static)
- name: Import tasks
  ansible.builtin.import_tasks: tasks/setup.yml

# Include with variables
- name: Include with vars
  ansible.builtin.include_tasks: tasks/deploy.yml
  vars:
    environment: production
```

## Tags

```yaml
tasks:
  - name: Tagged task
    ansible.builtin.command: /bin/command
    tags:
      - deploy
      - always  # Always runs regardless of tag selection

  - name: Never runs by default
    ansible.builtin.command: /bin/command
    tags: never  # Only runs when explicitly tagged
```

Run with tags:
```bash
ansible-playbook playbook.yml --tags "deploy"
ansible-playbook playbook.yml --skip-tags "slow"
```

## Check Mode

```yaml
# Force check mode behavior
- name: Always runs in check
  ansible.builtin.command: /bin/command
  check_mode: false  # Runs even in check mode

- name: Never runs in check
  ansible.builtin.command: /bin/command
  check_mode: true   # Only runs in check mode
```

## Delegation

```yaml
# Run on different host
- name: Update load balancer
  ansible.builtin.command: /bin/update-lb
  delegate_to: loadbalancer

# Run locally
- name: Local action
  ansible.builtin.command: /bin/local-command
  delegate_to: localhost

# Run once for all hosts
- name: Single execution
  ansible.builtin.command: /bin/command
  run_once: true
```

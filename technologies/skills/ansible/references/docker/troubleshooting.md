# Ansible Docker Troubleshooting

Common issues and debugging patterns.

## Module Issues

### "Could not find docker-compose"

```yaml
# docker_compose_v2 requires Docker Compose V2 (plugin)
# NOT standalone docker-compose binary

# Check on target host:
# docker compose version  # V2 (plugin)
# docker-compose version  # V1 (standalone) - won't work
```

Fix: Install Docker Compose V2:
```yaml
- name: Install Docker Compose plugin
  ansible.builtin.apt:
    name: docker-compose-plugin
    state: present
```

### "Permission denied"

```yaml
# User not in docker group
- name: Add user to docker group
  ansible.builtin.user:
    name: "{{ ansible_user }}"
    groups: docker
    append: true
  become: true

# Then reconnect or use become
- name: Run with become
  community.docker.docker_container:
    name: myapp
    # ...
  become: true
```

### "Cannot connect to Docker daemon"

```yaml
# Docker not running
- name: Ensure Docker is running
  ansible.builtin.service:
    name: docker
    state: started
    enabled: true
  become: true

# Socket permission issue
# Add become: true to docker tasks
```

## Container Issues

### Get container logs

```yaml
- name: Get logs
  community.docker.docker_container_exec:
    container: myapp
    command: cat /var/log/app.log
  register: logs
  ignore_errors: true

- name: Alternative - docker logs
  ansible.builtin.command: docker logs --tail 100 myapp
  register: docker_logs
  changed_when: false

- name: Show logs
  ansible.builtin.debug:
    var: docker_logs.stdout_lines
```

### Container keeps restarting

```yaml
- name: Get container info
  community.docker.docker_container_info:
    name: myapp
  register: container_info

- name: Show restart count
  ansible.builtin.debug:
    msg: "Restart count: {{ container_info.container.RestartCount }}"

- name: Show last exit code
  ansible.builtin.debug:
    msg: "Exit code: {{ container_info.container.State.ExitCode }}"

- name: Get logs from dead container
  ansible.builtin.command: docker logs myapp
  register: crash_logs
  changed_when: false

- name: Show crash logs
  ansible.builtin.debug:
    var: crash_logs.stderr_lines
```

### Health check failing

```yaml
- name: Check health status
  community.docker.docker_container_info:
    name: myapp
  register: info

- name: Show health
  ansible.builtin.debug:
    msg: |
      Status: {{ info.container.State.Health.Status }}
      Failing: {{ info.container.State.Health.FailingStreak }}
      Log: {{ info.container.State.Health.Log | last }}

# Manual health check
- name: Test health endpoint
  ansible.builtin.command: >
    docker exec myapp curl -f http://localhost:8080/health
  register: health
  ignore_errors: true
  changed_when: false
```

## Network Issues

### Container can't reach external network

```yaml
- name: Test DNS from container
  ansible.builtin.command: docker exec myapp nslookup google.com
  register: dns_test
  changed_when: false
  ignore_errors: true

- name: Test connectivity
  ansible.builtin.command: docker exec myapp ping -c 1 8.8.8.8
  register: ping_test
  changed_when: false
  ignore_errors: true

# Check iptables
- name: Check IP forwarding
  ansible.builtin.command: sysctl net.ipv4.ip_forward
  register: ip_forward
  changed_when: false

- name: Enable IP forwarding
  ansible.posix.sysctl:
    name: net.ipv4.ip_forward
    value: '1'
    state: present
  become: true
  when: "'0' in ip_forward.stdout"
```

### Containers can't communicate

```yaml
- name: List networks
  community.docker.docker_network_info:
    name: "{{ network_name }}"
  register: network_info

- name: Show connected containers
  ansible.builtin.debug:
    var: network_info.network.Containers

# Verify both containers on same network
- name: Test inter-container connectivity
  ansible.builtin.command: >
    docker exec app ping -c 1 db
  register: ping_result
  changed_when: false
```

## Compose Issues

### Services not starting in order

```yaml
# depends_on only waits for container start, not readiness
# Use healthcheck + condition

# In compose template:
services:
  app:
    depends_on:
      db:
        condition: service_healthy  # Wait for health check

  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready"]
      interval: 5s
      timeout: 5s
      retries: 5
```

### Orphaned containers

```yaml
# Containers from old compose runs
- name: Remove orphans
  community.docker.docker_compose_v2:
    project_src: /opt/myapp
    state: present
    remove_orphans: true
```

### Volume data not persisting

```yaml
# Check volume exists
- name: List volumes
  ansible.builtin.command: docker volume ls
  register: volumes
  changed_when: false

# Check volume contents
- name: Inspect volume
  ansible.builtin.command: docker volume inspect myapp_data
  register: volume_info
  changed_when: false

- name: Show volume mountpoint
  ansible.builtin.debug:
    msg: "{{ (volume_info.stdout | from_json)[0].Mountpoint }}"
```

## Debug Playbook

```yaml
---
- name: Docker debug
  hosts: docker_hosts
  tasks:
    - name: Docker version
      ansible.builtin.command: docker version
      register: docker_version
      changed_when: false

    - name: Compose version
      ansible.builtin.command: docker compose version
      register: compose_version
      changed_when: false

    - name: List containers
      ansible.builtin.command: docker ps -a
      register: containers
      changed_when: false

    - name: List images
      ansible.builtin.command: docker images
      register: images
      changed_when: false

    - name: Disk usage
      ansible.builtin.command: docker system df
      register: disk
      changed_when: false

    - name: Show all
      ansible.builtin.debug:
        msg: |
          Docker: {{ docker_version.stdout_lines[0] }}
          Compose: {{ compose_version.stdout }}
          Containers:
          {{ containers.stdout }}
          Images:
          {{ images.stdout }}
          Disk:
          {{ disk.stdout }}
```

## Common Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `docker.errors.DockerException` | Docker not running | Start docker service |
| `docker.errors.APIError: 404` | Container/image not found | Check name/tag |
| `docker.errors.APIError: 409` | Container name conflict | Remove or rename |
| `PermissionError` | Not in docker group | Add user or use become |
| `requests.exceptions.ConnectionError` | Docker socket inaccessible | Check socket permissions |
| `FileNotFoundError: docker-compose` | V1 compose not installed | Use docker_compose_v2 |

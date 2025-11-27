# Docker Deployment with Ansible

Managing Docker containers and compose stacks via Ansible.

## Collection Setup

```bash
ansible-galaxy collection install community.docker
```

## Compose Deployment (Recommended)

### Deploy from local compose file

```yaml
- name: Deploy application stack
  hosts: docker_hosts
  become: true
  tasks:
    - name: Create project directory
      ansible.builtin.file:
        path: /opt/myapp
        state: directory
        owner: "{{ ansible_user }}"
        mode: '0755'

    - name: Copy compose file
      ansible.builtin.template:
        src: docker-compose.yml.j2
        dest: /opt/myapp/docker-compose.yml
        owner: "{{ ansible_user }}"
        mode: '0644'

    - name: Copy environment file
      ansible.builtin.template:
        src: .env.j2
        dest: /opt/myapp/.env
        owner: "{{ ansible_user }}"
        mode: '0600'

    - name: Deploy with compose
      community.docker.docker_compose_v2:
        project_src: /opt/myapp
        state: present
        pull: always
      register: deploy_result

    - name: Show deployed services
      ansible.builtin.debug:
        var: deploy_result.containers
```

### Compose operations

```yaml
# Pull latest images and recreate
- name: Update stack
  community.docker.docker_compose_v2:
    project_src: /opt/myapp
    state: present
    pull: always
    recreate: always

# Stop stack (keep volumes)
- name: Stop stack
  community.docker.docker_compose_v2:
    project_src: /opt/myapp
    state: stopped

# Remove stack
- name: Remove stack
  community.docker.docker_compose_v2:
    project_src: /opt/myapp
    state: absent
    remove_volumes: false  # Keep data volumes
```

## Container Deployment (Individual)

### Run container

```yaml
- name: Run nginx container
  community.docker.docker_container:
    name: nginx
    image: nginx:1.25
    state: started
    restart_policy: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/nginx/html:/usr/share/nginx/html:ro
      - /opt/nginx/conf.d:/etc/nginx/conf.d:ro
    env:
      TZ: "America/Los_Angeles"
    labels:
      app: web
      env: production

- name: Run database
  community.docker.docker_container:
    name: postgres
    image: postgres:15
    state: started
    restart_policy: unless-stopped
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    env:
      POSTGRES_USER: "{{ db_user }}"
      POSTGRES_PASSWORD: "{{ db_password }}"
      POSTGRES_DB: "{{ db_name }}"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U {{ db_user }}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Container lifecycle

```yaml
# Stop container
- name: Stop container
  community.docker.docker_container:
    name: myapp
    state: stopped

# Restart container
- name: Restart container
  community.docker.docker_container:
    name: myapp
    state: started
    restart: true

# Remove container
- name: Remove container
  community.docker.docker_container:
    name: myapp
    state: absent

# Force recreate
- name: Recreate container
  community.docker.docker_container:
    name: myapp
    image: myapp:latest
    state: started
    recreate: true
```

## Image Management

```yaml
# Pull image
- name: Pull latest image
  community.docker.docker_image:
    name: myapp
    tag: latest
    source: pull
    force_source: true  # Always check for updates

# Build from Dockerfile
- name: Build image
  community.docker.docker_image:
    name: myapp
    tag: "{{ version }}"
    source: build
    build:
      path: /opt/myapp
      dockerfile: Dockerfile
      pull: true  # Pull base image updates

# Remove image
- name: Remove old images
  community.docker.docker_image:
    name: myapp
    tag: old
    state: absent
```

## Network Management

```yaml
# Create network
- name: Create app network
  community.docker.docker_network:
    name: app_network
    driver: bridge
    ipam_config:
      - subnet: 172.20.0.0/16
        gateway: 172.20.0.1

# Create macvlan network
- name: Create macvlan network
  community.docker.docker_network:
    name: lan
    driver: macvlan
    driver_options:
      parent: eth0
    ipam_config:
      - subnet: 192.168.1.0/24
        gateway: 192.168.1.1

# Attach container to network
- name: Run container on network
  community.docker.docker_container:
    name: myapp
    image: myapp:latest
    networks:
      - name: app_network
        ipv4_address: 172.20.0.10
```

## Volume Management

```yaml
# Create named volume
- name: Create data volume
  community.docker.docker_volume:
    name: app_data
    driver: local

# Create volume with options
- name: Create NFS volume
  community.docker.docker_volume:
    name: shared_data
    driver: local
    driver_options:
      type: nfs
      device: ":/exports/data"
      o: "addr=192.168.1.10,rw"

# Backup volume
- name: Backup volume
  community.docker.docker_container:
    name: backup
    image: alpine
    command: tar czf /backup/data.tar.gz /data
    volumes:
      - app_data:/data:ro
      - /opt/backups:/backup
    auto_remove: true
```

## Common Patterns

### Wait for service health

```yaml
- name: Deploy database
  community.docker.docker_container:
    name: postgres
    image: postgres:15
    # ... config ...

- name: Wait for database
  community.docker.docker_container_info:
    name: postgres
  register: db_info
  until: db_info.container.State.Health.Status == "healthy"
  retries: 30
  delay: 2
```

### Rolling update

```yaml
- name: Pull new image
  community.docker.docker_image:
    name: myapp
    tag: "{{ new_version }}"
    source: pull

- name: Update container
  community.docker.docker_container:
    name: myapp
    image: "myapp:{{ new_version }}"
    state: started
    recreate: true
    restart_policy: unless-stopped
```

### Cleanup

```yaml
- name: Remove stopped containers
  community.docker.docker_prune:
    containers: true
    containers_filters:
      status: exited

- name: Remove unused images
  community.docker.docker_prune:
    images: true
    images_filters:
      dangling: true

- name: Full cleanup (careful!)
  community.docker.docker_prune:
    containers: true
    images: true
    networks: true
    volumes: false  # Don't remove data!
    builder_cache: true
```

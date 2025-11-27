# Ansible Docker Compose Patterns

Common patterns for managing Docker Compose stacks with Ansible.

## Project Structure

```
roles/
└── docker_app/
    ├── tasks/
    │   └── main.yml
    ├── templates/
    │   ├── docker-compose.yml.j2
    │   └── .env.j2
    ├── defaults/
    │   └── main.yml
    └── handlers/
        └── main.yml
```

## Role Template

### defaults/main.yml

```yaml
app_name: myapp
app_version: latest
app_port: 8080
app_data_dir: "/opt/{{ app_name }}"

# Compose settings
compose_pull: always
compose_recreate: auto  # auto, always, never

# Resource limits
app_memory_limit: 512M
app_cpu_limit: 1.0
```

### templates/docker-compose.yml.j2

```yaml
name: {{ app_name }}

services:
  app:
    image: {{ app_image }}:{{ app_version }}
    container_name: {{ app_name }}
    restart: unless-stopped
    ports:
      - "{{ app_port }}:{{ app_internal_port | default(app_port) }}"
    volumes:
      - {{ app_data_dir }}/data:/app/data
{% if app_config_file is defined %}
      - {{ app_data_dir }}/config:/app/config:ro
{% endif %}
    environment:
      TZ: {{ timezone | default('UTC') }}
{% for key, value in app_env.items() %}
      {{ key }}: "{{ value }}"
{% endfor %}
{% if app_memory_limit is defined or app_cpu_limit is defined %}
    deploy:
      resources:
        limits:
{% if app_memory_limit is defined %}
          memory: {{ app_memory_limit }}
{% endif %}
{% if app_cpu_limit is defined %}
          cpus: '{{ app_cpu_limit }}'
{% endif %}
{% endif %}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{ app_internal_port | default(app_port) }}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - {{ app_network | default('default') }}

{% if app_network is defined %}
networks:
  {{ app_network }}:
    external: true
{% endif %}
```

### tasks/main.yml

```yaml
---
- name: Create application directory
  ansible.builtin.file:
    path: "{{ app_data_dir }}"
    state: directory
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0755'

- name: Create data directories
  ansible.builtin.file:
    path: "{{ app_data_dir }}/{{ item }}"
    state: directory
    owner: "{{ ansible_user }}"
    mode: '0755'
  loop:
    - data
    - config

- name: Deploy compose file
  ansible.builtin.template:
    src: docker-compose.yml.j2
    dest: "{{ app_data_dir }}/docker-compose.yml"
    owner: "{{ ansible_user }}"
    mode: '0644'
  notify: Redeploy stack

- name: Deploy environment file
  ansible.builtin.template:
    src: .env.j2
    dest: "{{ app_data_dir }}/.env"
    owner: "{{ ansible_user }}"
    mode: '0600'
  notify: Redeploy stack
  when: app_secrets is defined

- name: Ensure stack is running
  community.docker.docker_compose_v2:
    project_src: "{{ app_data_dir }}"
    state: present
    pull: "{{ compose_pull }}"
    recreate: "{{ compose_recreate }}"
  register: compose_result

- name: Show deployment result
  ansible.builtin.debug:
    msg: "Deployed {{ compose_result.containers | length }} containers"
  when: compose_result is changed
```

### handlers/main.yml

```yaml
---
- name: Redeploy stack
  community.docker.docker_compose_v2:
    project_src: "{{ app_data_dir }}"
    state: present
    pull: always
    recreate: always
```

## Multi-Service Stack

### templates/docker-compose.yml.j2 (full stack)

```yaml
name: {{ stack_name }}

services:
  app:
    image: {{ app_image }}:{{ app_version }}
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      DATABASE_URL: "postgres://{{ db_user }}:{{ db_password }}@db:5432/{{ db_name }}"
      REDIS_URL: "redis://redis:6379"
    networks:
      - internal
      - web

  db:
    image: postgres:15
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: {{ db_user }}
      POSTGRES_PASSWORD: {{ db_password }}
      POSTGRES_DB: {{ db_name }}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U {{ db_user }}"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - internal

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data
    networks:
      - internal

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "{{ http_port | default(80) }}:80"
      - "{{ https_port | default(443) }}:443"
    volumes:
      - {{ app_data_dir }}/nginx/conf.d:/etc/nginx/conf.d:ro
      - {{ app_data_dir }}/nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
    networks:
      - web

networks:
  internal:
    driver: bridge
  web:
    driver: bridge

volumes:
  db_data:
  redis_data:
```

## Zero-Downtime Update

```yaml
- name: Zero-downtime update
  hosts: docker_hosts
  serial: 1  # One host at a time
  tasks:
    - name: Pull new image
      community.docker.docker_image:
        name: "{{ app_image }}"
        tag: "{{ app_version }}"
        source: pull

    - name: Drain connections (if load balanced)
      # ... remove from load balancer ...

    - name: Update stack
      community.docker.docker_compose_v2:
        project_src: "{{ app_data_dir }}"
        state: present
        recreate: always

    - name: Wait for health
      ansible.builtin.uri:
        url: "http://localhost:{{ app_port }}/health"
        status_code: 200
      register: health
      until: health.status == 200
      retries: 30
      delay: 2

    - name: Restore to load balancer
      # ... add back to load balancer ...
```

## Secrets Management

### With ansible-vault

```yaml
# group_vars/secrets.yml (encrypted)
app_secrets:
  DB_PASSWORD: supersecret
  API_KEY: abc123
  JWT_SECRET: longsecret
```

```yaml
# templates/.env.j2
{% for key, value in app_secrets.items() %}
{{ key }}={{ value }}
{% endfor %}
```

### With external secrets

```yaml
- name: Fetch secret from 1Password
  ansible.builtin.set_fact:
    db_password: "{{ lookup('community.general.onepassword', 'database', field='password') }}"

- name: Deploy with secret
  community.docker.docker_compose_v2:
    project_src: "{{ app_data_dir }}"
    env_files:
      - "{{ app_data_dir }}/.env"
    state: present
```

# Ansible Modules Reference

## File Operations

### copy

```yaml
- name: Copy file
  ansible.builtin.copy:
    src: files/config.conf
    dest: /etc/app/config.conf
    owner: root
    group: root
    mode: '0644'
    backup: true
```

### template

```yaml
- name: Template config
  ansible.builtin.template:
    src: templates/config.j2
    dest: /etc/app/config.conf
    owner: root
    group: root
    mode: '0644'
  notify: Restart app
```

### file

```yaml
# Create directory
- name: Create directory
  ansible.builtin.file:
    path: /opt/app
    state: directory
    owner: app
    group: app
    mode: '0755'

# Create symlink
- name: Create symlink
  ansible.builtin.file:
    src: /opt/app/current
    dest: /opt/app/release
    state: link

# Delete file
- name: Remove file
  ansible.builtin.file:
    path: /tmp/old-file
    state: absent
```

### lineinfile

```yaml
- name: Ensure line in file
  ansible.builtin.lineinfile:
    path: /etc/hosts
    line: "192.168.1.10 myhost"
    state: present

- name: Replace line
  ansible.builtin.lineinfile:
    path: /etc/config
    regexp: '^PORT='
    line: 'PORT=8080'
```

## Package Management

### apt (Debian/Ubuntu)

```yaml
- name: Install package
  ansible.builtin.apt:
    name: nginx
    state: present
    update_cache: true

- name: Install multiple
  ansible.builtin.apt:
    name:
      - nginx
      - python3
    state: present

- name: Remove package
  ansible.builtin.apt:
    name: nginx
    state: absent
```

### package (Generic)

```yaml
- name: Install package
  ansible.builtin.package:
    name: httpd
    state: present
```

## Service Management

### service

```yaml
- name: Start and enable
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true

- name: Restart
  ansible.builtin.service:
    name: nginx
    state: restarted

- name: Reload
  ansible.builtin.service:
    name: nginx
    state: reloaded
```

### systemd

```yaml
- name: Daemon reload
  ansible.builtin.systemd:
    daemon_reload: true

- name: Enable and start
  ansible.builtin.systemd:
    name: myapp
    state: started
    enabled: true
```

## Command Execution

### command

```yaml
- name: Run command
  ansible.builtin.command: /bin/mycommand arg1 arg2
  register: result
  changed_when: "'changed' in result.stdout"
```

### shell

```yaml
- name: Run shell command
  ansible.builtin.shell: |
    cd /opt/app
    ./setup.sh && ./configure.sh
  args:
    executable: /bin/bash
```

### script

```yaml
- name: Run local script on remote
  ansible.builtin.script: scripts/setup.sh
  args:
    creates: /opt/app/.installed
```

## User Management

### user

```yaml
- name: Create user
  ansible.builtin.user:
    name: appuser
    groups: docker,sudo
    shell: /bin/bash
    create_home: true
    state: present

- name: Remove user
  ansible.builtin.user:
    name: olduser
    state: absent
    remove: true
```

### group

```yaml
- name: Create group
  ansible.builtin.group:
    name: appgroup
    state: present
```

## Docker (community.docker)

### docker_container

```yaml
- name: Run container
  community.docker.docker_container:
    name: myapp
    image: myapp:latest
    state: started
    restart_policy: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - /data:/app/data
    env:
      DB_HOST: database
```

### docker_compose_v2

```yaml
- name: Deploy with compose
  community.docker.docker_compose_v2:
    project_src: /opt/app
    project_name: myapp
    state: present
    pull: always
    env_files:
      - /opt/app/.env
```

### docker_image

```yaml
- name: Pull image
  community.docker.docker_image:
    name: nginx
    tag: "1.25"
    source: pull
```

## Networking

### uri

```yaml
- name: API call
  ansible.builtin.uri:
    url: "http://localhost:8080/api/health"
    method: GET
    return_content: true
  register: response

- name: POST request
  ansible.builtin.uri:
    url: "http://api.example.com/data"
    method: POST
    body_format: json
    body:
      key: value
```

### wait_for

```yaml
- name: Wait for port
  ansible.builtin.wait_for:
    host: localhost
    port: 8080
    timeout: 300

- name: Wait for file
  ansible.builtin.wait_for:
    path: /var/log/app.log
    search_regex: "Server started"
```

## Debug/Assert

### debug

```yaml
- name: Print variable
  ansible.builtin.debug:
    msg: "Value: {{ my_var }}"

- name: Print var directly
  ansible.builtin.debug:
    var: my_var
```

### assert

```yaml
- name: Validate conditions
  ansible.builtin.assert:
    that:
      - my_var is defined
      - my_var | length > 0
    fail_msg: "my_var must be defined and non-empty"
    success_msg: "Validation passed"
```

### fail

```yaml
- name: Fail with message
  ansible.builtin.fail:
    msg: "Required condition not met"
  when: condition
```

## Misc

### pause

```yaml
- name: Wait 10 seconds
  ansible.builtin.pause:
    seconds: 10

- name: Wait for user
  ansible.builtin.pause:
    prompt: "Press enter to continue"
```

### stat

```yaml
- name: Check file exists
  ansible.builtin.stat:
    path: /etc/config
  register: config_file

- name: Use result
  ansible.builtin.debug:
    msg: "File exists"
  when: config_file.stat.exists
```

# Packer Provisioners

## Provisioner Types

| Type | Use Case |
|------|----------|
| shell | Quick commands, scripts |
| shell-local | Commands on Packer host |
| file | Upload files to VM |
| ansible | Complex configuration |
| ansible-local | Ansible on the VM itself |

## Shell Provisioner

### Inline Commands

```hcl
provisioner "shell" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get upgrade -y",
    "sudo apt-get install -y qemu-guest-agent"
  ]
}
```

### Script File

```hcl
provisioner "shell" {
  script = "scripts/setup.sh"
}
```

### Multiple Scripts

```hcl
provisioner "shell" {
  scripts = [
    "scripts/01-update.sh",
    "scripts/02-install.sh",
    "scripts/99-cleanup.sh"
  ]
}
```

### Environment Variables

```hcl
provisioner "shell" {
  environment_vars = [
    "DEBIAN_FRONTEND=noninteractive",
    "MY_VAR=${var.my_variable}"
  ]
  script = "scripts/setup.sh"
}
```

### Execute Command

Override default execution:

```hcl
provisioner "shell" {
  execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  script = "scripts/setup.sh"
}
```

## File Provisioner

### Upload File

```hcl
provisioner "file" {
  source      = "files/config.conf"
  destination = "/tmp/config.conf"
}

provisioner "shell" {
  inline = ["sudo mv /tmp/config.conf /etc/app/config.conf"]
}
```

### Upload Directory

```hcl
provisioner "file" {
  source      = "files/"      # Trailing slash = contents
  destination = "/tmp/files"
}
```

## Ansible Provisioner

### Remote Execution

Runs Ansible from Packer host:

```hcl
provisioner "ansible" {
  playbook_file = "ansible/playbook.yml"

  extra_arguments = [
    "--extra-vars", "env=production",
    "-vvv"  # Verbose
  ]

  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False"
  ]
}
```

### With Inventory Groups

```hcl
provisioner "ansible" {
  playbook_file = "ansible/site.yml"
  groups        = ["webservers"]
}
```

### Ansible Local

Runs Ansible on the VM itself:

```hcl
provisioner "ansible-local" {
  playbook_file = "ansible/local.yml"

  # Upload these paths to VM
  playbook_dir  = "ansible/"
  role_paths    = ["ansible/roles/"]
}
```

## Provisioner Order

Best practice ordering:

```hcl
build {
  sources = ["source.proxmox-iso.ubuntu"]

  # 1. Update system first
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }

  # 2. Upload configuration files
  provisioner "file" {
    source      = "files/"
    destination = "/tmp/"
  }

  # 3. Main configuration (Ansible or scripts)
  provisioner "ansible" {
    playbook_file = "ansible/configure.yml"
  }

  # 4. Cleanup (always last)
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
```

## Common Cleanup Script

```bash
#!/bin/bash
# scripts/cleanup.sh

set -e

# Clean apt cache
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Remove temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clear machine-id (regenerated on first boot)
sudo truncate -s 0 /etc/machine-id

# Clear SSH host keys (regenerated on first boot)
sudo rm -f /etc/ssh/ssh_host_*

# Clear cloud-init for fresh run
sudo cloud-init clean --logs

# Clear bash history
cat /dev/null > ~/.bash_history
history -c

# Sync and clear caches
sync
```

## Error Handling

### Continue on Error

```hcl
provisioner "shell" {
  inline = ["some-command || true"]
}
```

### Only Run on Specific Builds

```hcl
provisioner "shell" {
  only   = ["proxmox-iso.ubuntu"]  # Only this source
  script = "scripts/proxmox-specific.sh"
}
```

### Except Specific Builds

```hcl
provisioner "shell" {
  except = ["amazon-ebs.ubuntu"]  # Skip for AWS
  script = "scripts/local-only.sh"
}
```

## Debugging Provisioners

```hcl
provisioner "shell" {
  inline = [
    "set -x",  # Print commands
    "whoami",
    "pwd",
    "env | sort"
  ]
}
```

# Module Design

## Standard Structure

```
modules/<name>/
├── main.tf       # Resources
├── variables.tf  # Inputs
├── outputs.tf    # Outputs
├── versions.tf   # Provider constraints
```

## Module Example

```hcl
# modules/vm/variables.tf
variable "name" {
  description = "VM name"
  type        = string
}

variable "target_node" {
  description = "Proxmox node"
  type        = string
}

variable "specs" {
  type = object({
    cores  = number
    memory = number
    disk   = optional(string, "50G")
  })
}
```

```hcl
# modules/vm/main.tf
resource "proxmox_vm_qemu" "vm" {
  name        = var.name
  target_node = var.target_node
  cores       = var.specs.cores
  memory      = var.specs.memory
}
```

```hcl
# modules/vm/outputs.tf
output "ip" {
  value = proxmox_vm_qemu.vm.default_ipv4_address
}
```

```hcl
# Usage
module "web" {
  source      = "./modules/vm"
  name        = "web-01"
  target_node = "pve1"
  specs       = { cores = 4, memory = 8192 }
}
```

## Complex Variable Types

```hcl
# Map of objects
variable "vms" {
  type = map(object({
    node   = string
    cores  = number
    memory = number
  }))
}

# Object with optional fields
variable "network" {
  type = object({
    bridge = string
    vlan   = optional(number)
    ip     = optional(string, "dhcp")
  })
}
```

## Variable Validation

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "cores" {
  type = number
  validation {
    condition     = var.cores >= 1 && var.cores <= 32
    error_message = "Cores must be 1-32."
  }
}
```

## Module Composition

```hcl
module "network" {
  source = "../../modules/network"
  # ...
}

module "web" {
  source     = "../../modules/vm"
  network_id = module.network.id  # Implicit dependency
}

module "database" {
  source     = "../../modules/vm"
  depends_on = [module.network]   # Explicit dependency
}
```

## for_each vs count

```hcl
# count - index-based (0, 1, 2)
module "worker" {
  source = "./modules/vm"
  count  = 3
  name   = "worker-${count.index}"
}
# Access: module.worker[0]

# for_each - key-based (preferred)
module "vm" {
  source   = "./modules/vm"
  for_each = var.vms
  name     = each.key
  specs    = each.value
}
# Access: module.vm["web"]
```

## Version Constraints

```hcl
# modules/vm/versions.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}
```

```hcl
# Pin module version
module "vm" {
  source = "git::https://github.com/org/modules.git//vm?ref=v2.1.0"
}
```

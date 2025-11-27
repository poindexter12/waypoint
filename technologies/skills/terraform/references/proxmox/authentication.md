# Proxmox Provider Authentication

## Provider Configuration

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://proxmox.example.com:8006/api2/json"
  pm_api_token_id     = "terraform@pve!mytoken"
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = false  # true for self-signed certs
  pm_parallel         = 4      # concurrent operations
  pm_timeout          = 600    # API timeout seconds
}
```

## Create API Token

```bash
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role PVEAdmin
pveum user token add terraform@pve mytoken
```

## Environment Variables

```bash
export PM_API_TOKEN_ID="terraform@pve!mytoken"
export PM_API_TOKEN_SECRET="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Official Resources

- [Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [GitHub](https://github.com/Telmate/terraform-provider-proxmox)
- [Proxmox API](https://pve.proxmox.com/pve-docs/api-viewer/)

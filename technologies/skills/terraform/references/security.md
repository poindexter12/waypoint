# Security

## Secrets Management

### Environment Variables (Recommended)

```bash
export TF_VAR_proxmox_password="secret"
export TF_VAR_api_token="xxxxx"
terraform apply
```

### Sensitive Variables

```hcl
variable "database_password" {
  type      = string
  sensitive = true  # Hidden in logs/plan
}
```

### External Secrets Managers

**HashiCorp Vault**:
```hcl
data "vault_generic_secret" "db" {
  path = "secret/database"
}

resource "some_resource" "x" {
  password = data.vault_generic_secret.db.data["password"]
}
```

**1Password CLI**:
```bash
export TF_VAR_password="$(op read 'op://vault/item/password')"
terraform apply
```

## State Security

**CRITICAL**: State contains secrets in plaintext.

### Encrypt at Rest

```hcl
backend "s3" {
  encrypt    = true
  kms_key_id = "arn:aws:kms:..."  # Optional KMS
}
```

### Restrict Access

- IAM/RBAC on backend storage
- Enable state locking
- Never commit state to git

## Provider Credentials

```hcl
provider "proxmox" {
  pm_api_token_id     = "terraform@pve!mytoken"
  pm_api_token_secret = var.pm_api_token_secret  # From env
}
```

Create minimal-permission API user:
```bash
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role PVEVMAdmin
pveum user token add terraform@pve terraform-token
```

## Sensitive Outputs

```hcl
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
```

## Checklist

- [ ] Sensitive vars marked `sensitive = true`
- [ ] Secrets via env vars or secrets manager
- [ ] State backend encryption enabled
- [ ] State locking enabled
- [ ] No credentials in .tf files
- [ ] Provider credentials minimal permissions

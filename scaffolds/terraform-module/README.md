# Terraform Module Scaffold

Copy these files into a new repository root when you want the repo to start as a Terraform module.

After copying:

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
```

Add provider-specific resources in `main.tf` after you decide what the module should manage.

When you add a real provider, pin it in `versions.tf` with a `required_providers` block.

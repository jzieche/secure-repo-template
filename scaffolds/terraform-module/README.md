# Terraform Boilerplate Template

This directory is a [Boilerplate](https://github.com/gruntwork-io/boilerplate) template for generating a Terraform module in the repository root.

## Render the template

```bash
boilerplate --template-url scaffolds/terraform-module --output-folder . --non-interactive
```

The template provides local Terraform defaults through `boilerplate.yml`, so the rendered module is valid without extra input.

## Template variables

The template exposes:

- `Name`
- `Description`
- `Enabled`
- `Tags`
- `RequiredVersion`
- `RequiredProviders`

Use `RequiredProviders` when you want `versions.tf` to render provider constraints. Supply it as a YAML list of objects with `name`, `source`, and `version` keys, for example:

```yaml
RequiredProviders:
  - name: aws
    source: hashicorp/aws
    version: "~> 5.0"
```

## Validate the rendered module

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
```

locals {
  normalized_name    = replace(replace(lower(trimspace(var.name)), "_", "-"), ".", "-")
  module_description = trimspace(var.description)
  module_enabled     = var.enabled
  common_tags = merge(var.tags, {
    module       = local.normalized_name
    "managed-by" = "terraform"
  })
}

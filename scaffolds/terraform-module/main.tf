locals {
  normalized_name = regexreplace(lower(trimspace(var.name)), "[^0-9a-z-]", "-")
  module_description = trimspace(var.description)
  common_tags = merge(var.tags, {
    module     = local.normalized_name
    "managed-by" = "terraform"
  })
}

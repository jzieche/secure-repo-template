output "name" {
  description = "Normalized module name."
  value       = local.normalized_name
}

output "description" {
  description = "Normalized module description."
  value       = local.module_description
}

output "enabled" {
  description = "Whether the module is enabled."
  value       = var.enabled
}

output "tags" {
  description = "Merged tags for the module."
  value       = local.common_tags
}

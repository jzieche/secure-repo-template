variable "name" {
  description = "Name used to identify the module."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-z](?:[0-9a-z-]*[0-9a-z])?$", lower(trimspace(var.name))))
    error_message = "name must start and end with an alphanumeric character and may contain only alphanumerics or hyphens."
  }
}

variable "description" {
  description = "Optional description for the module."
  type        = string
  default     = ""
}

variable "enabled" {
  description = "Controls whether the module should be considered enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to attach to resources created by the module."
  type        = map(string)
  default     = {}
}

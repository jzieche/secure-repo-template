variable "name" {
  description = "Name used to identify the module."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0 && can(regex("[0-9A-Za-z]", trimspace(var.name)))
    error_message = "name must not be empty and must contain at least one alphanumeric character."
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

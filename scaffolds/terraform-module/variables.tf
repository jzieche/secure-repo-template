variable "name" {
  description = "Name used to identify the module."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
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

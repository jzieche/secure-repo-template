variable "name" {
  description = "Name used to identify the module."
  type        = string
  default     = {{ printf "%q" .Name }}

  validation {
    condition     = can(regex("^[A-Za-z0-9](?:[A-Za-z0-9_.-]*[A-Za-z0-9])?$", trimspace(var.name)))
    error_message = "name must start and end with an alphanumeric character and may only contain alphanumerics, dots, underscores, or hyphens in between."
  }
}

variable "description" {
  description = "Optional description for the module."
  type        = string
  default     = {{ printf "%q" .Description }}
}

variable "enabled" {
  description = "Controls whether the module should be considered enabled."
  type        = bool
  default     = {{ .Enabled }}
}

variable "tags" {
  description = "Tags to attach to resources created by the module."
  type        = map(string)
{{- if .Tags }}
  default     = {
{{- $keys := keys .Tags | sortAlpha }}
{{- $width := 0 }}
{{- range $key := $keys }}
{{- $width = max $width (len (printf "%q" $key)) }}
{{- end }}
{{- range $key := $keys }}
    {{ printf "%-*s = %q" $width (printf "%q" $key) (index $.Tags $key) }}
{{- end }}
  }
{{- else }}
  default     = {}
{{- end }}
}

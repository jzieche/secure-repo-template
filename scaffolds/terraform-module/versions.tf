terraform {
  required_version = {{ printf "%q" .RequiredVersion }}
{{- if .RequiredProviders }}

  required_providers {
{{- $providers := .RequiredProviders }}
{{- $width := 0 }}
{{- range $provider := $providers }}
{{- $width = max $width (len $provider.name) }}
{{- end }}
{{- range $provider := $providers }}
    {{ printf "%-*s = {" $width $provider.name }}
      source  = {{ printf "%q" $provider.source }}
      version = {{ printf "%q" $provider.version }}
    }
{{- end }}
  }
{{- end }}
}

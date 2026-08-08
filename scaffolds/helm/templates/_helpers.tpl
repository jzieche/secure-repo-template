{{ printf `{{- define "%s.name" -}}` .ChartName }}
{{ `{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}` }}
{{ `{{- end -}}` }}

{{ printf `{{- define "%s.fullname" -}}` .ChartName }}
{{ `{{- if .Values.fullnameOverride -}}` }}
{{ `{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}` }}
{{ `{{- else -}}` }}
{{ printf `{{- printf "%%s-%%s" .Release.Name (include "%s.name" .) | trunc 63 | trimSuffix "-" -}}` .ChartName }}
{{ `{{- end -}}` }}
{{ `{{- end -}}` }}

{{ printf `{{- define "%s.labels" -}}` .ChartName }}
app.kubernetes.io/name: {{ printf `{{ include "%s.name" . }}` .ChartName }}
app.kubernetes.io/instance: {{ `{{ .Release.Name }}` }}
app.kubernetes.io/managed-by: {{ `{{ .Release.Service }}` }}
helm.sh/chart: {{ `{{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}` }}
{{ `{{- end -}}` }}

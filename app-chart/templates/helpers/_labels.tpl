{{/*
Standard labels
*/}}
{{- define "app-chart.labels" -}}
app.kubernetes.io/name: {{ .appName }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
{{- if .context.Chart.AppVersion }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
app: {{ .appName }}
{{- end -}}

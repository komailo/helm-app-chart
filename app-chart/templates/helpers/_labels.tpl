{{/*
Standard labels – applied to all resources rendered by the chart.
Includes the Kubernetes recommended labels and the legacy "app" selector.
*/}}
{{- define "app-chart.labels" -}}
app.kubernetes.io/name: {{ .appName }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
{{- if .context.Chart.AppVersion }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/component: {{ .component | default "app" }}
app.kubernetes.io/part-of: {{ .context.Release.Name }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
app: {{ .appName }}
{{- end -}}

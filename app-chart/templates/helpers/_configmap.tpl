{{/* Shared helpers for ConfigMap resources */}}
{{- define "app-chart.configmap.fullName" -}}
{{- $name := required "configMap name is required" .name -}}
{{- $spec := .spec | default (dict) -}}
{{- $override := default $name $spec.nameOverride -}}
{{- printf "%s" $override | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app-chart.configmap.volumeName" -}}
{{- $appName := required "appName is required" .appName -}}
{{- $configName := required "configMap reference name is required" .name -}}
{{- printf "%s-%s" $appName $configName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

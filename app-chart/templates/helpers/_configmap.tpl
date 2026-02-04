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

{{- define "app-chart.configmap.renderData" -}}
{{- $data := . | default (dict) -}}
{{- range $key, $value := $data }}
  {{- if or (kindIs "map" $value) (kindIs "slice" $value) }}
{{ printf "%s: |-\n%s" $key (toYaml $value | indent 2) }}
  {{- else }}
{{ toYaml (dict $key $value) }}
  {{- end }}
{{- end -}}
{{- end -}}

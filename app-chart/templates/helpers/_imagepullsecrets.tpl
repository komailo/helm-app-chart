{{/*
Renders imagePullSecrets pod spec section for a workload.
Usage: {{ include "app-chart.imagePullSecrets.render" (dict "workloadSecrets" $app.imagePullSecrets "context" $) }}
*/}}
{{- define "app-chart.imagePullSecrets.render" -}}
{{- $context := .context -}}
{{- $workloadSecrets := .workloadSecrets -}}
{{- $names := dict -}}
{{- $ordered := list -}}

{{/* 1. Global / root-level imagePullSecrets */}}
{{- with $context.Values.imagePullSecrets -}}
  {{- if kindIs "slice" . -}}
    {{- range . -}}
      {{- $name := "" -}}
      {{- $enabled := true -}}
      {{- if kindIs "string" . -}}
        {{- $name = . -}}
      {{- else if kindIs "map" . -}}
        {{- $name = .name -}}
        {{- if hasKey . "enabled" -}}
          {{- $enabled = .enabled -}}
        {{- end -}}
      {{- end -}}
      {{- if and $name $enabled (not (hasKey $names $name)) -}}
        {{- $_ := set $names $name true -}}
        {{- $ordered = append $ordered $name -}}
      {{- end -}}
    {{- end -}}
  {{- else if kindIs "map" . -}}
    {{- range $key, $val := . -}}
      {{- $name := $key -}}
      {{- $enabled := true -}}
      {{- if kindIs "map" $val -}}
        {{- $name = default $key $val.name -}}
        {{- if hasKey $val "enabled" -}}
          {{- $enabled = $val.enabled -}}
        {{- end -}}
      {{- end -}}
      {{- if and $name $enabled (not (hasKey $names $name)) -}}
        {{- $_ := set $names $name true -}}
        {{- $ordered = append $ordered $name -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* 2. defaults.imagePullSecrets */}}
{{- $defaults := default (dict) $context.Values.defaults -}}
{{- with $defaults.imagePullSecrets -}}
  {{- if kindIs "slice" . -}}
    {{- range . -}}
      {{- $name := "" -}}
      {{- $enabled := true -}}
      {{- if kindIs "string" . -}}
        {{- $name = . -}}
      {{- else if kindIs "map" . -}}
        {{- $name = .name -}}
        {{- if hasKey . "enabled" -}}
          {{- $enabled = .enabled -}}
        {{- end -}}
      {{- end -}}
      {{- if and $name $enabled (not (hasKey $names $name)) -}}
        {{- $_ := set $names $name true -}}
        {{- $ordered = append $ordered $name -}}
      {{- end -}}
    {{- end -}}
  {{- else if kindIs "map" . -}}
    {{- range $key, $val := . -}}
      {{- $name := $key -}}
      {{- $enabled := true -}}
      {{- if kindIs "map" $val -}}
        {{- $name = default $key $val.name -}}
        {{- if hasKey $val "enabled" -}}
          {{- $enabled = $val.enabled -}}
        {{- end -}}
      {{- end -}}
      {{- if and $name $enabled (not (hasKey $names $name)) -}}
        {{- $_ := set $names $name true -}}
        {{- $ordered = append $ordered $name -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* 3. Workload-level imagePullSecrets */}}
{{- with $workloadSecrets -}}
  {{- if kindIs "slice" . -}}
    {{- range . -}}
      {{- $name := "" -}}
      {{- $enabled := true -}}
      {{- if kindIs "string" . -}}
        {{- $name = . -}}
      {{- else if kindIs "map" . -}}
        {{- $name = .name -}}
        {{- if hasKey . "enabled" -}}
          {{- $enabled = .enabled -}}
        {{- end -}}
      {{- end -}}
      {{- if and $name $enabled (not (hasKey $names $name)) -}}
        {{- $_ := set $names $name true -}}
        {{- $ordered = append $ordered $name -}}
      {{- end -}}
    {{- end -}}
  {{- else if kindIs "map" . -}}
    {{- range $key, $val := . -}}
      {{- $name := $key -}}
      {{- $enabled := true -}}
      {{- if kindIs "map" $val -}}
        {{- $name = default $key $val.name -}}
        {{- if hasKey $val "enabled" -}}
          {{- $enabled = $val.enabled -}}
        {{- end -}}
      {{- end -}}
      {{- if and $name $enabled (not (hasKey $names $name)) -}}
        {{- $_ := set $names $name true -}}
        {{- $ordered = append $ordered $name -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if gt (len $ordered) 0 -}}
imagePullSecrets:
{{- range $ordered }}
  - name: {{ . }}
{{- end -}}
{{- end -}}
{{- end -}}

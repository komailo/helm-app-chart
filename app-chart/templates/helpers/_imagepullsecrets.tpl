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

{{/*
Collects all ExternalSecret definitions declared across imagePullSecrets sources.
Returns a JSON-encoded map of secretName -> config dictionary.
*/}}
{{- define "app-chart.imagePullSecrets.collectExternalSecrets" -}}
{{- $context := . -}}
{{- $collected := dict -}}
{{- $sources := list -}}

{{- with $context.Values.imagePullSecrets -}}
  {{- $sources = append $sources . -}}
{{- end -}}

{{- $defaults := default (dict) $context.Values.defaults -}}
{{- with $defaults.imagePullSecrets -}}
  {{- $sources = append $sources . -}}
{{- end -}}

{{- range $appName, $app := $context.Values.apps -}}
  {{- if or (not (hasKey $app "enabled")) $app.enabled -}}
    {{- with $app.imagePullSecrets -}}
      {{- $sources = append $sources . -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- range $jobName, $job := $context.Values.cronJobs -}}
  {{- if or (not (hasKey $job "enabled")) $job.enabled -}}
    {{- $pod := default (dict) $job.pod -}}
    {{- with $pod.imagePullSecrets -}}
      {{- $sources = append $sources . -}}
    {{- end -}}
    {{- with $job.imagePullSecrets -}}
      {{- $sources = append $sources . -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- range $src := $sources -}}
  {{- if kindIs "slice" $src -}}
    {{- range $item := $src -}}
      {{- if kindIs "map" $item -}}
        {{- if $item.remoteRefKey -}}
          {{- $name := required "imagePullSecrets items with remoteRefKey require a name" $item.name -}}
          {{- $enabled := true -}}
          {{- if hasKey $item "enabled" -}}
            {{- $enabled = $item.enabled -}}
          {{- end -}}
          {{- if $enabled -}}
            {{- $_ := set $collected $name $item -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- else if kindIs "map" $src -}}
    {{- range $key, $val := $src -}}
      {{- if kindIs "map" $val -}}
        {{- if $val.remoteRefKey -}}
          {{- $name := default $key $val.name -}}
          {{- $enabled := true -}}
          {{- if hasKey $val "enabled" -}}
            {{- $enabled = $val.enabled -}}
          {{- end -}}
          {{- if $enabled -}}
            {{- $item := merge (dict "name" $name) $val -}}
            {{- $_ := set $collected $name $item -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- toJson $collected -}}
{{- end -}}

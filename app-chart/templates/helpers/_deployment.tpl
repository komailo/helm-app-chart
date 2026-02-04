{{/* Renders container ports for a single app */}}
{{- define "app-chart.deployment.containerPorts" -}}
{{- $ports := .ports -}}
{{- $appName := .appName -}}
{{- if $ports -}}
ports:
{{- range $port := $ports }}
{{- $containerPort := default 80 $port.containerPort }}
{{- $portName := default (printf "%s-%d" $appName $containerPort) $port.name }}
{{- $protocol := default "TCP" $port.protocol }}
  - containerPort: {{ $containerPort }}
    name: {{ $portName }}
    protocol: {{ $protocol }}
{{- end }}
{{- end -}}
{{- end }}

{{/* Renders envFrom sources for a container */}}
{{- define "app-chart.deployment.envFrom" -}}
{{- $envFrom := .envFrom -}}
{{- if $envFrom -}}
envFrom:
{{- toYaml $envFrom | nindent 2 -}}
{{- end -}}
{{- end }}

{{/* Renders env vars with tpl support for values */}}
{{- define "app-chart.deployment.env" -}}
{{- $env := .env -}}
{{- $context := .context -}}
{{- $appName := .appName -}}
{{- if $env -}}
env:
{{- range $idx, $entry := $env }}
  - name: {{ required (printf "apps.%s.env[%d].name is required" $appName $idx) $entry.name }}
    {{- if hasKey $entry "valueFrom" }}
    valueFrom:
{{ tpl (toYaml $entry.valueFrom) $context | nindent 6 }}
    {{- else if hasKey $entry "value" }}
    value: {{ tpl $entry.value $context | quote }}
    {{- else }}
    {{- fail (printf "apps.%s.env[%d] requires either value or valueFrom" $appName $idx) }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Renders optional livenessProbe for a container */}}
{{- define "app-chart.deployment.livenessProbe" -}}
{{- $probe := .livenessProbe -}}
{{- $appName := .appName -}}
{{- if $probe -}}
  {{- $enabled := true -}}
  {{- if hasKey $probe "enabled" -}}
    {{- $enabled = $probe.enabled -}}
  {{- end -}}
  {{- if $enabled -}}
livenessProbe:
  {{- $probeType := default "command" $probe.type }}
  {{- if eq $probeType "command" }}
  exec:
    command:
    {{- $command := required (printf "apps.%s.livenessProbe.command is required when type=command" $appName) $probe.command }}
    {{- range $cmd := $command }}
      - {{ $cmd | quote }}
    {{- end }}
  {{- else if eq $probeType "http" }}
  httpGet:
    {{- $port := required (printf "apps.%s.livenessProbe.port is required when type=http" $appName) $probe.port }}
    {{- $path := default "/" $probe.path }}
    path: {{ $path | quote }}
    port: {{ $port }}
    {{- with $probe.host }}
    host: {{ . | quote }}
    {{- end }}
    {{- with $probe.scheme }}
    scheme: {{ . | quote }}
    {{- end }}
    {{- with $probe.httpHeaders }}
    httpHeaders:
    {{- range $idx, $header := . }}
      - name: {{ required (printf "apps.%s.livenessProbe.httpHeaders[%d].name is required" $appName $idx) $header.name | quote }}
        value: {{ required (printf "apps.%s.livenessProbe.httpHeaders[%d].value is required" $appName $idx) $header.value | quote }}
    {{- end }}
    {{- end }}
  {{- else }}
  {{- fail (printf "apps.%s.livenessProbe.type %s is not supported" $appName $probeType) }}
  {{- end }}
  {{- with $probe.initialDelaySeconds }}
  initialDelaySeconds: {{ . }}
  {{- end }}
  {{- with $probe.periodSeconds }}
  periodSeconds: {{ . }}
  {{- end }}
  {{- with $probe.timeoutSeconds }}
  timeoutSeconds: {{ . }}
  {{- end }}
  {{- with $probe.successThreshold }}
  successThreshold: {{ . }}
  {{- end }}
  {{- with $probe.failureThreshold }}
  failureThreshold: {{ . }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Renders optional readinessProbe for a container */}}
{{- define "app-chart.deployment.readinessProbe" -}}
{{- $probe := .readinessProbe -}}
{{- $appName := .appName -}}
{{- if $probe -}}
  {{- $enabled := true -}}
  {{- if hasKey $probe "enabled" -}}
    {{- $enabled = $probe.enabled -}}
  {{- end -}}
  {{- if $enabled -}}
readinessProbe:
  {{- $probeType := default "command" $probe.type }}
  {{- if eq $probeType "command" }}
  exec:
    command:
    {{- $command := required (printf "apps.%s.readinessProbe.command is required when type=command" $appName) $probe.command }}
    {{- range $cmd := $command }}
      - {{ $cmd | quote }}
    {{- end }}
  {{- else if eq $probeType "http" }}
  httpGet:
    {{- $port := required (printf "apps.%s.readinessProbe.port is required when type=http" $appName) $probe.port }}
    {{- $path := default "/" $probe.path }}
    path: {{ $path | quote }}
    port: {{ $port }}
    {{- with $probe.host }}
    host: {{ . | quote }}
    {{- end }}
    {{- with $probe.scheme }}
    scheme: {{ . | quote }}
    {{- end }}
    {{- with $probe.httpHeaders }}
    httpHeaders:
    {{- range $idx, $header := . }}
      - name: {{ required (printf "apps.%s.readinessProbe.httpHeaders[%d].name is required" $appName $idx) $header.name | quote }}
        value: {{ required (printf "apps.%s.readinessProbe.httpHeaders[%d].value is required" $appName $idx) $header.value | quote }}
    {{- end }}
    {{- end }}
  {{- else }}
  {{- fail (printf "apps.%s.readinessProbe.type %s is not supported" $appName $probeType) }}
  {{- end }}
  {{- with $probe.initialDelaySeconds }}
  initialDelaySeconds: {{ . }}
  {{- end }}
  {{- with $probe.periodSeconds }}
  periodSeconds: {{ . }}
  {{- end }}
  {{- with $probe.timeoutSeconds }}
  timeoutSeconds: {{ . }}
  {{- end }}
  {{- with $probe.successThreshold }}
  successThreshold: {{ . }}
  {{- end }}
  {{- with $probe.failureThreshold }}
  failureThreshold: {{ . }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Renders volumeMounts for containers */}}
{{- define "app-chart.deployment.volumeMounts" -}}
{{- $appName := .appName -}}
{{- $volumes := .volumes | default (list) -}}
{{- $configMounts := .configMounts | default (list) -}}
{{- $configMaps := .configMaps | default (dict) -}}
{{- $ctx := dict "mounts" (list) -}}
{{- range $volumes }}
  {{- $mount := dict "name" (required "volumes[].name is required" .name) "mountPath" (required "mountPath is required for volumeMounts" .mountPath) -}}
  {{- if hasKey . "subPath" }}
    {{- $_ := set $mount "subPath" .subPath }}
  {{- end }}
  {{- $_ := set $ctx "mounts" (append ($ctx.mounts) $mount) }}
{{- end }}
{{- range $mountIdx, $mount := $configMounts }}
  {{- $configName := required (printf "apps.%s.configMounts[%d].name is required" $appName $mountIdx) $mount.name }}
  {{- $configSpec := index $configMaps $configName }}
  {{- if not $configSpec }}
    {{- fail (printf "apps.%s.configMounts[%d].name %q not found under configMaps" $appName $mountIdx $configName) }}
  {{- end }}
  {{- $configEnabled := true }}
  {{- if hasKey $configSpec "enabled" }}
    {{- $configEnabled = $configSpec.enabled }}
  {{- end }}
  {{- if not $configEnabled }}
    {{- fail (printf "apps.%s.configMounts[%d].name %q references a disabled configMaps entry" $appName $mountIdx $configName) }}
  {{- end }}
  {{- $volumeName := include "app-chart.configmap.volumeName" (dict "appName" $appName "name" $configName) }}
  {{- $entry := dict "name" $volumeName "mountPath" (required (printf "apps.%s.configMounts[%d].path is required" $appName $mountIdx) $mount.path) -}}
  {{- if hasKey $mount "subPath" }}
    {{- $_ := set $entry "subPath" $mount.subPath }}
  {{- end }}
  {{- $readOnly := true }}
  {{- if hasKey $mount "readOnly" }}
    {{- $readOnly = $mount.readOnly }}
  {{- end }}
  {{- $_ := set $entry "readOnly" $readOnly }}
  {{- $_ := set $ctx "mounts" (append ($ctx.mounts) $entry) }}
{{- end }}
{{- $mounts := $ctx.mounts -}}
{{- if gt (len $mounts) 0 }}
volumeMounts:
{{- range $mount := $mounts }}
  - name: {{ $mount.name }}
    mountPath: {{ $mount.mountPath }}
    {{- with $mount.subPath }}
    subPath: {{ . }}
    {{- end }}
    {{- if hasKey $mount "readOnly" }}
    readOnly: {{ $mount.readOnly }}
    {{- end }}
{{- end }}
{{- end -}}
{{- end }}

{{/* Renders pod volumes */}}
{{- define "app-chart.deployment.volumes" -}}
{{- $appName := .appName -}}
{{- $volumes := .volumes | default (list) -}}
{{- $configMounts := .configMounts | default (list) -}}
{{- if or (gt (len $volumes) 0) (gt (len $configMounts) 0) }}
volumes:
{{- $seen := dict }}
{{- range $idx, $volume := $volumes }}
  {{- $volumeName := required (printf "volumes[%d].name is required" $idx) $volume.name }}
  {{- if not (hasKey $seen $volumeName) }}
  - name: {{ $volumeName }}
    persistentVolumeClaim:
      claimName: {{ $volume.persistentVolumeClaim.claimName }}
  {{- $_ := set $seen $volumeName true }}
  {{- end }}
{{- end }}
{{- $configMaps := .configMaps | default (dict) -}}
{{- range $mountIdx, $mount := $configMounts }}
  {{- $configName := required (printf "apps.%s.configMounts[%d].name is required" $appName $mountIdx) $mount.name }}
  {{- $configSpec := index $configMaps $configName }}
  {{- if not $configSpec }}
    {{- fail (printf "apps.%s.configMounts[%d].name %q not found under configMaps" $appName $mountIdx $configName) }}
  {{- end }}
  {{- $configEnabled := true }}
  {{- if hasKey $configSpec "enabled" }}
    {{- $configEnabled = $configSpec.enabled }}
  {{- end }}
  {{- if not $configEnabled }}
    {{- fail (printf "apps.%s.configMounts[%d].name %q references a disabled configMaps entry" $appName $mountIdx $configName) }}
  {{- end }}
  {{- $volumeName := include "app-chart.configmap.volumeName" (dict "appName" $appName "name" $configName) }}
  {{- if hasKey $seen $volumeName }}
    {{- continue }}
  {{- end }}
  {{- $configMetaName := include "app-chart.configmap.fullName" (dict "name" $configName "spec" $configSpec) }}
  - name: {{ $volumeName }}
    configMap:
      name: {{ $configMetaName }}
      {{- with $configSpec.defaultMode }}
      defaultMode: {{ . }}
      {{- end }}
      {{- if $configSpec.items }}
      items:
        {{- range $itemIdx, $item := $configSpec.items }}
        - key: {{ required (printf "configMaps.%s.items[%d].key is required" $configName $itemIdx) $item.key }}
          path: {{ required (printf "configMaps.%s.items[%d].path is required" $configName $itemIdx) $item.path }}
          {{- with $item.mode }}
          mode: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
  {{- $_ := set $seen $volumeName true }}
{{- end }}
{{- end -}}
{{- end }}

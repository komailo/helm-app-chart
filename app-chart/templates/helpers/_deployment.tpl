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
{{- $volumes := .volumes -}}
{{- if $volumes -}}
volumeMounts:
{{- range $volume := $volumes }}
  - name: {{ $volume.name }}
    mountPath: {{ $volume.mountPath | required "mountPath is required for volumeMounts" }}
    {{- if $volume.subPath }}
    subPath: {{ $volume.subPath }}
    {{- end }}
{{- end }}
{{- end -}}
{{- end }}

{{/* Renders pod volumes */}}
{{- define "app-chart.deployment.volumes" -}}
{{- $volumes := .volumes -}}
{{- if $volumes -}}
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
{{- end -}}
{{- end }}

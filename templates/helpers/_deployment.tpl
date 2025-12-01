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

{{/* Renders optional livenessProbe for a container */}}
{{- define "app-chart.deployment.livenessProbe" -}}
{{- $probe := .livenessProbe -}}
{{- $appName := .appName -}}
{{- if and $probe (ne ($probe.enabled | default true) false) -}}
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

{{/* Renders volumeMounts for containers */}}
{{- define "app-chart.deployment.volumeMounts" -}}
{{- $volumes := .volumes -}}
{{- if $volumes -}}
volumeMounts:
{{- range $volume := $volumes }}
  - name: {{ $volume.name }}
    mountPath: {{ $volume.mountPath | required "mountPath is required for volumeMounts" }}
{{- end }}
{{- end -}}
{{- end }}

{{/* Renders pod volumes */}}
{{- define "app-chart.deployment.volumes" -}}
{{- $volumes := .volumes -}}
{{- if $volumes -}}
volumes:
{{- range $volume := $volumes }}
  - name: {{ $volume.name }}
    persistentVolumeClaim:
        claimName: {{ $volume.persistentVolumeClaim.claimName }}
{{- end }}
{{- end -}}
{{- end }}

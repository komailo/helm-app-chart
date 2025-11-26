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

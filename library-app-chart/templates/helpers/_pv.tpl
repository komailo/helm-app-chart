{{/* Renders a PersistentVolume manifest */}}
{{- define "library-app-chart.pv.volume" -}}
{{- $name := required "pv.volume requires a name" .name -}}
{{- $pv := required (printf "persistentVolumes.%s is required" $name) .pv -}}
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ $name }}
  {{- with $pv.labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  storageClassName: {{ $pv.storageClassName | default "manual" }}
  capacity:
    storage: {{ $pv.storage | default $pv.capacity }}
  accessModes:
    {{- if $pv.accessModes }}
    {{- range $pv.accessModes }}
    - {{ . }}
    {{- end }}
    {{- else }}
    - ReadWriteOnce
    {{- end }}
  persistentVolumeReclaimPolicy: {{ $pv.reclaimPolicy | default "Retain" }}
  {{- if $pv.hostPath }}
  hostPath:
    {{- if typeIs "string" $pv.hostPath }}
    path: {{ $pv.hostPath | quote }}
    {{- else }}
    path: {{ $pv.hostPath.path | quote }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/* Renders a PersistentVolumeClaim manifest */}}
{{- define "library-app-chart.pv.claim" -}}
{{- $name := required "pv.claim requires a pvc name" .name -}}
{{- $pvc := required (printf "persistentVolumeClaims.%s is required" $name) .pvc -}}
{{- $root := required "pv.claim requires the root context" .root -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
  {{- with $pvc.labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  storageClassName: {{ $pvc.storageClassName | default "manual" }}
  accessModes:
    {{- if $pvc.accessModes }}
    {{- range $pvc.accessModes }}
    - {{ . }}
    {{- end }}
    {{- else }}
    - ReadWriteOnce
    {{- end }}
  resources:
    requests:
      storage: {{ $pvc.storage }}
  {{- with $pvc.selector }}
  selector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

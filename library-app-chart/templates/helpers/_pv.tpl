{{/* Renders a PersistentVolume manifest */}}
{{- define "library-app-chart.pv.volume" -}}
{{- $name := required "pv.volume requires a name" .name -}}
{{- $pv := required (printf "persistentVolumes.%s is required" $name) .pv -}}
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ $name }}
spec:
  storageClassName: {{ $pv.storageClassName | default "manual" }}
  capacity:
    storage: {{ $pv.capacity }}
  accessModes:
    {{- range $pv.accessModes }}
    - {{ . }}
    {{- end }}
  hostPath:
    path: {{ $pv.hostPath | quote }}
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
spec:
  storageClassName: {{ $pvc.storageClassName }}
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
{{- end -}}

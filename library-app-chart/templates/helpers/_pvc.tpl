{{/* Renders a PersistentVolumeClaim manifest for reuse */}}
{{- define "library-app-chart.pvc.claim" -}}
{{- $name := required "pvc.claim requires a pvc name" .name -}}
{{- $pvc := required (printf "persistentVolumeClaims.%s is required" $name) .pvc -}}
{{- $root := required "pvc.claim requires the root context" .root -}}

{{- if $pvc.hostPath -}}
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ $name }}-pv
  labels:
    volume-name: {{ $name }}
spec:
  storageClassName: {{ $pvc.storageClassName | default (printf "%s-sc" $name) }}
  capacity:
    storage: {{ $pvc.storage }}
  accessModes:
    - {{ $pvc.accessMode | default "ReadWriteOnce" }}
  persistentVolumeReclaimPolicy: {{ $pvc.reclaimPolicy | default "Retain" }}
  hostPath:
    path: {{ $pvc.hostPath | quote }}
{{- end }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
spec:
  {{- if $pvc.hostPath }}
  storageClassName: {{ $pvc.storageClassName | default (printf "%s-sc" $name) }}
  {{- else }}
  storageClassName: {{ $pvc.storageClassName }}
  {{- end }}
  accessModes:
    - {{ $pvc.accessMode | default "ReadWriteOnce" }}
  resources:
    requests:
      storage: {{ $pvc.storage }}
  {{- if $pvc.hostPath }}
  selector:
    matchLabels:
      volume-name: {{ $name }}
  {{- end }}
{{- end -}}

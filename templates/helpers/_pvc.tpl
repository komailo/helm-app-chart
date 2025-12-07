{{/* Renders a PersistentVolumeClaim manifest for reuse */}}
{{- define "app-chart.pvc.claim" -}}
{{- $name := required "pvc.claim requires a pvc name" .name -}}
{{- $pvc := required (printf "persistentVolumeClaims.%s is required" $name) .pvc -}}
{{- $root := required "pvc.claim requires the root context" .root -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
spec:
  storageClassName: {{ $pvc.storageClassName }}
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ $pvc.storage }}
{{- end -}}

{{/*
Renders a Restic maintenance CronJob with shared defaults so sibling charts can call it with different schedules and commands.
*/}}
{{- define "library-app-chart.restic.cronJob" -}}
{{- $root := required "restic.cronJob requires the root context" .root -}}
{{- $job := required "restic.cronJob requires a job map" .job -}}
{{- $name := required "restic.cronJob requires a job name" $job.name -}}
{{- $schedule := required (printf "restic.cronJob %s requires a schedule" $name) $job.schedule -}}
{{- $script := required (printf "restic.cronJob %s requires a script" $name) $job.script -}}
{{- $cachePVCName := required (printf "restic.cronJob %s requires cachePVCName" $name) $root.Values.resticBackup.cachePVC.name -}}
{{- $secretName := default "restic-backup" $job.envSecretName -}}
{{- $configMapName := default $secretName $job.configMapName -}}
{{- $containerName := default "restic" $job.containerName -}}
{{- $successfulHistory := default 1 $job.successfulJobsHistoryLimit -}}
{{- $failedHistory := default 1 $job.failedJobsHistoryLimit -}}
{{- $concurrencyPolicy := default "Forbid" $job.concurrencyPolicy -}}
{{- $ttlSeconds := $job.ttlSecondsAfterFinished | default 172800 -}}
{{- $backoffLimit := $job.backoffLimit | default 4 -}}
{{- $restartPolicy := default "OnFailure" $job.restartPolicy -}}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
spec:
  schedule: {{ $schedule | quote }}
  successfulJobsHistoryLimit: {{ $successfulHistory }}
  failedJobsHistoryLimit: {{ $failedHistory }}
  concurrencyPolicy: {{ $concurrencyPolicy }}
  jobTemplate:
    spec:
{{- if $ttlSeconds }}
      ttlSecondsAfterFinished: {{ $ttlSeconds }}
{{- end }}
{{- if $backoffLimit }}
      backoffLimit: {{ $backoffLimit }}
{{- end }}
      template:
        spec:
          restartPolicy: {{ $restartPolicy }}
          containers:
            - name: {{ $containerName }}
              image: {{ $job.image.repository }}:{{ $job.image.tag }}
              envFrom:
                - secretRef:
                    name: {{ $secretName }}
                  prefix: "RESTIC_"
                - configMapRef:
                    name: {{ $configMapName }}
                  prefix: "RESTIC_"
              volumeMounts:
                - name: restic-cache
                  mountPath: /cache/restic
              command:
                - /bin/sh
                - -c
                - |
                  set -euo pipefail

                  export B2_ACCOUNT_ID=${RESTIC_b2_account_id}
                  export B2_ACCOUNT_KEY=${RESTIC_b2_account_key}
                  export RESTIC_PASSWORD=${RESTIC_password}
                  export RESTIC_REPOSITORY=${RESTIC_repository}
                  export RESTIC_CACHE_DIR=/cache/restic

{{ $script | nindent 18 }}

          volumes:
            - name: restic-cache
              persistentVolumeClaim:
                claimName: {{ $cachePVCName | quote }}
{{- end -}}

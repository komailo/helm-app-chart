{{/*
Renders a Restic maintenance CronJob with shared defaults so sibling charts can call it with different schedules and commands.
*/}}
{{- define "library-app-chart.restic.cronJob" -}}
{{- $root := required "restic.cronJob requires the root context" .root -}}
{{- $job := required "restic.cronJob requires a job map" .job -}}
{{- $name := required "restic.cronJob requires a job name" $job.name -}}
{{- $schedule := default "" $job.schedule -}}
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
{{- $suspend := default false $job.suspend -}}
{{- if not $schedule -}}
  {{- $schedule = "0 0 1 1 */30" -}}
  {{- $suspend = true -}}
{{- end -}}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
spec:
  schedule: {{ $schedule | quote }}
  suspend: {{ $suspend }}
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

                  export RESTIC_PASSWORD=${RESTIC_password}
                  export RESTIC_REPOSITORY=${RESTIC_repository}
                  export RESTIC_CACHE_DIR=/cache/restic

                  # Setup SSH key and known_hosts for SFTP/rsync.net if private key is provided
                  if [ -n "${RESTIC_ssh_private_key:-}" ]; then
                    echo "[ssh] SSH private key found, preparing connection wrapper..."
                    SSH_DIR="/cache/restic/.ssh"
                    mkdir -p "$SSH_DIR"
                    chmod 700 "$SSH_DIR"

                    # Write the private key
                    echo "$RESTIC_ssh_private_key" > "$SSH_DIR/id_rsa"
                    chmod 600 "$SSH_DIR/id_rsa"

                    # Write known_hosts if fingerprint/known_hosts is provided
                    if [ -n "${RESTIC_ssh_known_hosts:-}" ]; then
                      echo "$RESTIC_ssh_known_hosts" > "$SSH_DIR/known_hosts"
                      chmod 600 "$SSH_DIR/known_hosts"
                    elif [ -n "${RESTIC_ssh_host_fingerprint:-}" ]; then
                      echo "$RESTIC_ssh_host_fingerprint" > "$SSH_DIR/known_hosts"
                      chmod 600 "$SSH_DIR/known_hosts"
                    else
                      touch "$SSH_DIR/known_hosts"
                      chmod 600 "$SSH_DIR/known_hosts"
                    fi

                    # Create a wrapper script to run ssh with correct options
                    cat << 'EOF' > "$SSH_DIR/ssh-wrapper.sh"
#!/bin/sh
exec ssh -i /cache/restic/.ssh/id_rsa -o UserKnownHostsFile=/cache/restic/.ssh/known_hosts -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes "$@"
EOF
                    chmod 700 "$SSH_DIR/ssh-wrapper.sh"

                    export RESTIC_SFTP_ARGS="-o sftp.command=/cache/restic/.ssh/ssh-wrapper.sh"
                  else
                    export RESTIC_SFTP_ARGS=""
                  fi

                  # Define restic wrapper to automatically inject SSH options if configured
                  restic() {
                    if [ -n "${RESTIC_SFTP_ARGS:-}" ]; then
                      command restic ${RESTIC_SFTP_ARGS} "$@"
                    else
                      command restic "$@"
                    fi
                  }

{{ $script | nindent 18 }}

          volumes:
            - name: restic-cache
              persistentVolumeClaim:
                claimName: {{ $cachePVCName | quote }}
{{- end -}}

# app-chart

Reusable Helm chart for deploying one or more simple applications (Deployments + Services + optional Ingress) from a single `values.yaml`. Each entry under `values.apps` describes an app's container image, replica count, exposed ports, service policy, and ingress configuration.

## Features

- Multi-app support: declare any number of workloads below `values.apps`
- Batch workloads: declare CronJobs under `values.cronJobs` for lightweight scheduled tasks
- Sensible defaults: ports, service exposure, and ingress fields auto-populate when omitted
- Config data: declare shared ConfigMaps once and mount them into any workload
- Namespace bootstrap: optionally create the release namespace from the chart
- Plain Helm: no custom controllers or CRDs, so rendering works anywhere Helm 3 does
- PVC management: define persistent volumes once and (optionally) back them up with a built-in Restic CronJob

## Getting Started

```sh
helm dependency update      # no-op today, keeps workflow consistent
helm lint .                 # required validation
helm template .             # check rendered manifests
helm upgrade --install my-app . \
  --namespace demo --create-namespace \
  --values values.yaml      # or a custom values file
```

Use ad-hoc `values-<feature>.yaml` files locally to exercise new combinations (multiple apps, ingress on/off, NodePort services, etc.). Do not commit files containing secrets.

## Publishing to GitHub Packages (OCI)

The CI workflow pushes every chart build to GitHub Packages as an OCI artifact under `ghcr.io/<owner>/helm`. Consume it via Helm 3.8+:

```sh
helm registry login ghcr.io -u <github-username> --password <github-token>
helm pull oci://ghcr.io/<owner>/helm/app-chart --version <chart-version>
```

The workflow uses `${{ secrets.GITHUB_TOKEN }}` with `packages: write` permissions, so no extra secrets are required.

## Values Overview

`values.yaml` is intentionally business-focused: describe what each service needs (replicas, endpoints, ports) and let the templates translate that input into Kubernetes manifests.

### Top-Level Keys

| Key                      | Type       | Description                                                                                        | Default |
| ------------------------ | ---------- | -------------------------------------------------------------------------------------------------- | ------- |
| `apps`                   | object map | Map of app name → configuration. Each entry renders a Deployment, Service, and optional Ingress.   | `{}`    |
| `configMaps`             | object map | Shared ConfigMaps rendered once and mounted into workloads via `apps.<name>.configMounts`.         | `{}`    |
| `cronJobs`               | object map | Map of CronJob name → configuration. Each entry renders a single-container CronJob.                | `{}`    |
| `namespace.enabled`      | bool       | When `true`, renders `templates/namespace.yaml` so Helm creates the target namespace.              | `false` |
| `persistentVolumeClaims` | object map | Map of PVC name → spec. Renders both `PersistentVolumeClaim` objects and optional backup CronJobs. | `{}`    |

### `apps.<name>` object

| Key                | Type   | Description                                                                                                               | Default                                                |
| ------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `enabled`          | bool   | Turns the entire app on/off without removing its config.                                                                  | `true`                                                 |
| `replicas`         | int    | Number of pod replicas.                                                                                                   | `1`                                                    |
| `image.repository` | string | Container image repository (e.g., `traefik/whoami`).                                                                      | **required**                                           |
| `image.tag`        | string | Image tag; falls back to `latest` if omitted.                                                                             | `latest`                                               |
| `args`             | array  | Optional array of arguments passed to the container. Each element is a string.                                             | `[]`                                                   |
| `envFrom`          | array  | Array of Kubernetes `envFrom` entries (ConfigMapRefs, SecretRefs, etc.) copied verbatim into the Deployment.              | `[]`                                                   |
| `configMounts`     | array  | Mount definitions referencing shared `configMaps`. Each entry sets a target path/`subPath`/`readOnly`.                 | `[]`                                                   |
| `ports`            | array  | Port definitions exposed on the container; also drives Service ports.                                                     | `[{ name: "http", containerPort: 80, protocol: TCP }]` |
| `service`          | object | App-wide Service defaults (e.g., `type: ClusterIP`). Per-port service overrides live under `ports[].service`.             | `{ type: ClusterIP }`                                  |
| `ingress`          | object | Optional ingress declaration. If `ingress.enabled` and hosts exist, renders `templates/ingress.yaml`.                     | disabled                                               |
| `livenessProbe`    | object | Optional container liveness probe. Currently supports `type: command` with a `command` array plus standard timing fields. | disabled                                               |

### `configMaps.<name>` object

Define shared ConfigMaps once and mount them into any workload via `apps.<name>.configMounts`. The map key becomes the default Kubernetes object name unless `nameOverride` is supplied.

| Key            | Type   | Description                                                                                               | Default |
| -------------- | ------ | --------------------------------------------------------------------------------------------------------- | ------- |
| `enabled`      | bool   | Toggle without deleting the block.                                                                         | `true`  |
| `nameOverride` | string | Optional explicit ConfigMap name. Falls back to the map key when omitted.                                 | unset   |
| `labels`       | map    | Extra labels merged into metadata.                                                                         | `{}`    |
| `annotations`  | map    | Extra annotations merged into metadata.                                                                    | `{}`    |
| `data`         | map    | String key/value pairs copied to the ConfigMap `data` field.                                               | `{}`    |
| `binaryData`   | map    | Base64-encoded blobs copied to `binaryData`. Required when `data` is empty.                                | `{}`    |
| `defaultMode`  | int    | File mode used when the ConfigMap is projected as a volume (Kubernetes interprets it as octal).           | `420` (Kubernetes default) |
| `items[]`      | array  | Optional key remapping for projected volumes. Each entry defines `key`, `path`, and optional `mode`.       | `[]`    |

Example:

```yaml
configMaps:
  shared-config:
    data:
      config.yaml: |
        baseUrl: https://whoami.local
        features:
          onboarding: true
apps:
  whoami:
    image:
      repository: traefik/whoami
    configMounts:
      - name: shared-config
        path: /etc/whoami
        readOnly: true
      - name: shared-config
        path: /etc/whoami/config.yaml
        subPath: config.yaml
```

### `configMounts[]` entries

Each app's `configMounts` array declares where a shared ConfigMap should be attached inside the pod. The referenced `name` must exist under the chart-level `configMaps` map.

| Key        | Type   | Description                                                                                 | Default |
| ---------- | ------ | ------------------------------------------------------------------------------------------- | ------- |
| `name`     | string | Required reference to `configMaps.<name>`.                                                   | —       |
| `path`     | string | Required container path fed to `volumeMounts[].mountPath`.                                  | —       |
| `subPath`  | string | Optional `subPath` when only one file from the ConfigMap should appear at `path`.          | unset   |
| `readOnly` | bool   | Defaults to `true`; set `false` only when the container needs to write to the mount path. | `true`  |

### `cronJobs.<name>` object

Each entry renders a Kubernetes `CronJob` with a single container definition. Values default to sensible Kubernetes defaults unless noted.

| Key                                    | Type   | Description                                                                                                     | Default        |
| -------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------- | -------------- |
| `enabled`                              | bool   | Toggle without deleting config.                                                                                 | `true`         |
| `schedule`                             | string | Cron schedule (`* * * * *`). **Required.**                                                                      | —              |
| `concurrencyPolicy`                    | string | `Allow`, `Forbid`, or `Replace`.                                                                                | `Allow`        |
| `suspend`                              | bool   | Pauses new schedules when `true`.                                                                               | unset          |
| `successfulJobsHistoryLimit`           | int    | Successful job history retained.                                                                                | `3`            |
| `failedJobsHistoryLimit`               | int    | Failed job history retained.                                                                                    | `1`            |
| `startingDeadlineSeconds`              | int    | Time window for catching up missed schedules.                                                                   | unset          |
| `jobTemplate.backoffLimit`             | int    | Backoff limit passed to the generated Job.                                                                      | unset          |
| `jobTemplate.ttlSecondsAfterFinished`  | int    | TTL for finished Jobs.                                                                                          | unset          |
| `jobTemplate.activeDeadlineSeconds`    | int    | Maximum run time for a Job before Kubernetes marks it failed.                                                   | unset          |
| `jobTemplate.parallelism`              | int    | Number of pods that can run in parallel.                                                                        | unset          |
| `jobTemplate.completions`              | int    | Total successful pods required to mark the Job complete.                                                        | unset          |
| `pod.restartPolicy`                    | string | Pod restart policy (`OnFailure` or `Never`).                                                                    | `OnFailure`    |
| `pod.serviceAccountName`               | string | ServiceAccount bound to the Job pod.                                                                            | unset          |
| `pod.nodeSelector`                     | object | Node selector passed to the pod spec.                                                                           | `{}`           |
| `pod.imagePullSecrets`                 | array  | Optional `imagePullSecrets` list.                                                                               | `[]`           |
| `pod.tolerations`                      | array  | Tolerations for taints.                                                                                         | `[]`           |
| `pod.affinity`                         | object | Affinity/anti-affinity rules.                                                                                   | `{}`           |
| `pod.securityContext`                  | object | Pod-level security context.                                                                                     | `{}`           |
| `container.name`                       | string | Container name. Defaults to the CronJob key.                                                                    | job key        |
| `container.image.repository`           | string | Container image repository. **Required.**                                                                       | —              |
| `container.image.tag`                  | string | Image tag.                                                                                                      | `latest`       |
| `container.image.pullPolicy`           | string | Image pull policy.                                                                                              | `IfNotPresent` |
| `container.command` / `container.args` | array  | Optional overrides for the container command and args.                                                          | unset          |
| `container.envFrom`                    | array  | Copied verbatim into `envFrom`.                                                                                 | `[]`           |
| `container.env`                        | array  | Same templated env structure as Deployments (supports `tpl` and `valueFrom`).                                   | `[]`           |
| `container.resources`                  | object | Resource requests/limits map.                                                                                   | `{}`           |
| `container.securityContext`            | object | Container-level security context.                                                                               | `{}`           |
| `volumes[]`                            | array  | Optional shared volume definitions reused for mounts and pod volumes (same structure as `apps.<name>.volumes`). | `[]`           |

Example:

```yaml
cronJobs:
  nightly-report:
    schedule: "0 * * * *"
    concurrencyPolicy: Forbid
    container:
      image:
        repository: busybox
      command:
        - /bin/sh
        - -c
      args:
        - echo "Collected metrics" && date
    pod:
      restartPolicy: OnFailure
    volumes:
      - name: data
        mountPath: /data
        persistentVolumeClaim:
          claimName: uptime-kuma-data
```

### `ports[]` entries

| Key                  | Type       | Description                                                                                        |
| -------------------- | ---------- | -------------------------------------------------------------------------------------------------- |
| `name`               | string     | Name applied to both the container port and Service port. Defaults to `<appName>-<containerPort>`. |
| `containerPort`      | int        | Container port exposed by the pod. Defaults to `80`.                                               |
| `protocol`           | string     | `TCP` or `UDP`. Defaults to `TCP`.                                                                 |
| `service.enabled`    | bool       | Disable to keep the port internal to the pod only.                                                 |
| `service.type`       | string     | Kubernetes Service type for this port (inherits from `apps.<name>.service.type` when omitted).     |
| `service.port`       | int        | External Service port number. Defaults to `containerPort`.                                         |
| `service.targetPort` | int/string | Pod port targeted by the Service. Defaults to the port `name`.                                     |
| `service.nodePort`   | int        | Required only when the Service type is `NodePort`/`LoadBalancer`.                                  |

### `ingress` block

| Key                        | Type   | Description                                                                                                                                                                                                              |
| -------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `enabled`                  | bool   | Turns ingress rendering on.                                                                                                                                                                                              |
| `className`                | string | `spec.ingressClassName`.                                                                                                                                                                                                 |
| `annotations`              | object | Arbitrary annotations applied to the Ingress metadata.                                                                                                                                                                   |
| `certManagerClusterIssuer` | string | Convenience field that adds the `cert-manager.io/cluster-issuer` annotation to the Ingress metadata.                                                                                                                     |
| `hosts[]`                  | array  | Host definitions. Each host may define `paths[]` with `path`, `pathType`, `serviceName`, and `servicePort`. When `serviceName` is omitted, defaults to the app name. `servicePort` accepts either a port name or number. |
| `tls[]`                    | array  | TLS entries; each entry's `hosts` array is copied verbatim. Secret names default to the app name.                                                                                                                        |

### Example

```yaml
apps:
  whoami:
    enabled: true
    replicas: 2
    image:
      repository: traefik/whoami
      tag: v1.10.2
    ports:
      - name: http
        containerPort: 8080
        service:
          port: 80
    ingress:
      enabled: true
      className: nginx
      certManagerClusterIssuer: letsencrypt-prod
      hosts:
        - host: whoami.local
          paths:
            - path: /
              pathType: Prefix
              servicePort: http
      tls:
        - hosts:
            - whoami.local
```

Copy the example block, rename the key (`whoami` → new service), and adjust ports/ingress requirements to onboard additional applications.

### `persistentVolumeClaims.<name>` objects

Every entry under `persistentVolumeClaims` renders a PVC from `templates/pvc.yaml`. Add a matching `volumes[].persistentVolumeClaim.claimName` inside the consuming app to mount it.

| Key                | Type   | Description                                                                                                | Default      |
| ------------------ | ------ | ---------------------------------------------------------------------------------------------------------- | ------------ |
| `storageClassName` | string | Required. Class the PVC should bind to.                                                                    | **required** |
| `storage`          | string | Required. Capacity request (for example `10Gi`).                                                           | **required** |
| `backup.enabled`   | bool   | When `true`, also renders `templates/pvc-backup.yaml`, which provisions Restic CronJobs + Secret per PVC.  | `false`      |
| `backup.schedule`  | string | Optional Cron expression for the snapshot job. Falls back to `defaults.backup.schedule`.                   | `*/30 * * * *` |
| `backup.forgetSchedule` | string | Optional Cron expression for the retention job. Falls back to `defaults.backup.forgetSchedule`.       | `@daily`     |
| `backup.pruningPolicy` | object | Optional overrides to the Retention policy used by the forget job.                                      | see values   |

When backups are enabled:

- One CronJob handles snapshots (default every 30 minutes) using `restic/restic`, backing up `/data` (the mounted PVC).
- A second CronJob enforces retention once per day with `restic forget` so that expensive Backblaze transactions only occur daily.
- Secrets referenced inside the backup template rely on external secret injection (see the `<path:...>` placeholders). Update those secret references to match your vault or secret store if needed.

Example:

```yaml
persistentVolumeClaims:
  uptime-kuma-data:
    storageClassName: production-1
    storage: 10Gi
    backup:
      enabled: true
# ... other chart values ...
apps:
  uptime-kuma:
    volumes:
      - name: uptime-kuma-data
        mountPath: /app/data
        persistentVolumeClaim:
          claimName: uptime-kuma-data
```

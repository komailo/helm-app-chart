# app-chart

Reusable Helm chart for deploying one or more simple applications (Deployments + Services + optional Ingress) from a single `values.yaml`. Each entry under `values.apps` describes an app's container image, replica count, exposed ports, service policy, and ingress configuration.

## Features

- Multi-app support: declare any number of workloads below `values.apps`
- Sensible defaults: ports, service exposure, and ingress fields auto-populate when omitted
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
| `namespace.enabled`      | bool       | When `true`, renders `templates/namespace.yaml` so Helm creates the target namespace.              | `false` |
| `persistentVolumeClaims` | object map | Map of PVC name → spec. Renders both `PersistentVolumeClaim` objects and optional backup CronJobs. | `{}`    |

### `apps.<name>` object

| Key                | Type   | Description                                                                                                               | Default                                                |
| ------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `enabled`          | bool   | Turns the entire app on/off without removing its config.                                                                  | `true`                                                 |
| `replicas`         | int    | Number of pod replicas.                                                                                                   | `1`                                                    |
| `image.repository` | string | Container image repository (e.g., `traefik/whoami`).                                                                      | **required**                                           |
| `image.tag`        | string | Image tag; falls back to `latest` if omitted.                                                                             | `latest`                                               |
| `ports`            | array  | Port definitions exposed on the container; also drives Service ports.                                                     | `[{ name: "http", containerPort: 80, protocol: TCP }]` |
| `service`          | object | App-wide Service defaults (e.g., `type: ClusterIP`). Per-port service overrides live under `ports[].service`.             | `{ type: ClusterIP }`                                  |
| `ingress`          | object | Optional ingress declaration. If `ingress.enabled` and hosts exist, renders `templates/ingress.yaml`.                     | disabled                                               |
| `livenessProbe`    | object | Optional container liveness probe. Currently supports `type: command` with a `command` array plus standard timing fields. | disabled                                               |

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
| `backup.enabled`   | bool   | When `true`, also renders `templates/pvc-backup.yaml`, which provisions a Restic CronJob + Secret per PVC. | `false`      |

When backups are enabled:

- The CronJob runs hourly using `restic/restic:latest`, backs up `/data` (the mounted PVC), and retains 7 daily, 4 weekly, and 3 monthly restore points.
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

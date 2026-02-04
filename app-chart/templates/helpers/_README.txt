Deployment helper snippets that keep `templates/deployment.yaml` small and composable:

- app-chart.deployment.containerPorts: expands `ports` arrays into container port entries.
- app-chart.deployment.envFrom: copies any `apps.<name>.envFrom` array verbatim into the pod spec.
- app-chart.deployment.env: renders `apps.<name>.env` entries, templating `value` strings via `tpl` and supporting `valueFrom` blocks.
- app-chart.deployment.livenessProbe: emits optional liveness probes configured via `apps.<name>.livenessProbe`.
- app-chart.deployment.readinessProbe: emits optional readiness probes configured via `apps.<name>.readinessProbe`.
- app-chart.deployment.volumeMounts: renders container `volumeMounts` from PVCs plus the app's `configMounts`.
- app-chart.deployment.volumes: renders pod `volumes` for PVCs and shared ConfigMaps referenced via `configMounts`.

ConfigMap helper snippets backing `templates/configmap.yaml`:

- app-chart.configmap.fullName: builds deterministic ConfigMap names from `values.configMaps` entries (honoring `nameOverride`).
- app-chart.configmap.volumeName: builds per-app volume names referencing shared ConfigMaps.
- app-chart.configmap.renderData: stringifies map or list `data` entries so ConfigMaps always receive string values.

PVC helper snippets for `templates/pvc.yaml` and other PVC consumers:

- app-chart.pvc.claim: renders a PVC manifest from `values.persistentVolumeClaims`, keeping namespace scoping and storage settings centralized.

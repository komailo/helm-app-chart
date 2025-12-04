Deployment helper snippets that keep `templates/deployment.yaml` small and composable:

- app-chart.deployment.containerPorts: expands `ports` arrays into container port entries.
- app-chart.deployment.envFrom: copies any `apps.<name>.envFrom` array verbatim into the pod spec.
- app-chart.deployment.env: renders `apps.<name>.env` entries, templating `value` strings via `tpl` and supporting `valueFrom` blocks.
- app-chart.deployment.livenessProbe: emits optional liveness probes configured via `apps.<name>.livenessProbe`.
- app-chart.deployment.readinessProbe: emits optional readiness probes configured via `apps.<name>.readinessProbe`.
- app-chart.deployment.volumeMounts: renders container `volumeMounts` from `apps.<name>.volumes`.
- app-chart.deployment.volumes: renders pod `volumes` that back the mounts with PVCs.

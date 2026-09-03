# Helm App Charts

This repository now bundles three sibling Helm charts so they can share the same helpers, CI pipeline, and release cadence.

| Chart                | Type        | Purpose                                                                                    |
| -------------------- | ----------- | ------------------------------------------------------------------------------------------ |
| `app-chart/`         | application | Multi-app workload chart (Deployments, Services, optional Ingress, CronJobs, PVC helpers). |
| `meta-app-chart/`    | application | Placeholder chart for future higher-level bundles.                                         |
| `library-app-chart/` | library     | Shared helper definitions consumed by the other charts.                                    |

## Local Development

1. Work inside the chart directory you are testing (`cd app-chart`, `cd meta-app-chart`, etc.).
2. Run `helm dependency update .` so Helm links the local `library-app-chart` dependency.
3. Run `helm lint .` and `helm template . --values values.yaml` (or any ad-hoc values file).

The application charts declare the library dependency using a relative `file://../library-app-chart` repository address so that development across sibling charts stays in sync. When the charts are packaged or published, Helm will vendor the current local copy of the library chart into `charts/` automatically.

## Configuration & Feature Flags

### Private Repository Pull Secrets (`imagePullSecrets`)

The chart supports pulling container images from private registries (GHCR, Docker Hub, AWS ECR, private registries) by reusing the built-in `esm` (External Secrets Manager) subchart and AWS Parameter Store:

- **Secret Creation with `esm`**: Define secrets under `esm.SimpleSecrets` with `dataSecretKey: .dockerconfigjson` pointing to your AWS Parameter Store path (`remoteRefKey`).
- **Reusable Global / Default Wiring**: Define `imagePullSecrets` at the root or under `defaults.imagePullSecrets` to automatically wire the pull secret into all `Deployments`, `CronJobs`, and backup jobs.
- **Per-App Overrides**: Specify `apps.<name>.imagePullSecrets` to attach dedicated pull secrets to specific workloads.
- **Existing Secret Support**: Reference existing Kubernetes Secret names directly in `imagePullSecrets`.

Example:

```yaml
esm:
  SimpleSecrets:
    - name: ghcr-pull-secret
      dataSecretKey: .dockerconfigjson
      remoteRefKey: /k8s-cluster/pull-secrets/ghcr

imagePullSecrets:
  - ghcr-pull-secret
```



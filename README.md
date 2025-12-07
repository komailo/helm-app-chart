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

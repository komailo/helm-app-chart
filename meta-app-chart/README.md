# meta-app-chart

This chart will eventually compose a collection of application bundles while sharing helpers from `library-app-chart`. It currently ships with Restic maintenance CronJobs that demonstrate how sibling charts can invoke shared helpers (e.g., `library-app-chart.restic.cronJob`) while keeping deployment logic dry.

## Restic backup knobs

`values.yaml` exposes a `resticBackup` block that drives a ConfigMap plus two CronJobs:

- `resticBackup.pruneJob` controls the pruning schedule/parameters.
- `resticBackup.checkJob` runs `restic check` on its own cadence.

Each job inherits the same pod spec via the shared helper, so you only need to tweak schedules (or overrides like `backoffLimit`, `image`, etc.) per job. If a job (e.g., prune) omits a schedule, the helper assigns a placeholder `0 0 1 1 */30` cadence and marks the CronJob as suspended so it will not fire until you provide a real schedule.

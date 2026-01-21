Helper snippets:

- `library-app-chart.pvc.claim`: renders a PVC manifest from `values.persistentVolumeClaims`, keeping namespace scoping and storage settings centralized.
- `library-app-chart.restic.cronJob`: renders a parametrized CronJob for Restic maintenance tasks (prune, check, etc.). When a schedule is omitted it auto-suspends the job and assigns a placeholder cadence so controllers stay quiet until the caller sets a real schedule.

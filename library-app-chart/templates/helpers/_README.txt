Helper snippets:

- `library-app-chart.pvc.claim`: renders a PVC manifest from `values.persistentVolumeClaims`, keeping namespace scoping and storage settings centralized.
- `library-app-chart.restic.cronJob`: renders a parametrized CronJob for Restic maintenance tasks (prune, check, etc.) so sibling charts can reuse identical specs with different schedules.

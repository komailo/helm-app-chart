# Repository Guidelines

## Project Structure & Current State

The working chart lives under `charts/app-chart` and follows the standard Helm layout: `Chart.yaml` carries metadata, `values.yaml` contains the multi-app defaults, and `templates/` renders Kubernetes objects via `deployment.yaml`, `service.yaml`, `ingress.yaml`, and the optional `namespace.yaml`. The chart now supports defining **any number of apps** under `values.apps`, each with its own replica count, ports, service strategy, and ingress configuration—the commented `apps.whoami` block in `values.yaml` is the canonical example to copy when adding new workloads. Keep helper files beside the templates they affect and prefer small, composable template snippets over large conditional blocks.

## Build, Test, and Validation Commands

Run Helm commands from this directory:

```sh
helm lint .
helm template . --values values.yaml
helm upgrade --install app . --namespace demo --dry-run
```

`helm lint` should pass before every commit. Use `helm template` (with any ad-hoc `values-<name>.yaml`) to verify rendering for new combinations, and finish with the dry-run upgrade command against the namespace you plan to target. Do not commit value files that contain secrets or personal overrides.

## Values Design & Coding Style

`values.yaml` must read from a service-owner perspective: describe intent (apps, ingress needs, desired ports) and let the templates translate to Kubernetes structures. YAML uses two-space indentation and lowercase hyphenated keys. Template files rely on Go template trimming (`{{- ... -}}`) to keep manifests tidy. Favor boolean `enabled` flags for toggles (`apps.<name>.enabled`, `apps.<name>.ingress.enabled`, `namespace.enabled`) and name two-dimensional structures by what they configure (e.g., `ports[].service.nodePort`). Metadata names must remain DNS-1123 compliant; templates currently derive them from the entry's app key.

### Template Behaviors to Be Aware Of
- `deployment.yaml` auto-inferrs defaults for missing port definitions (`http` @ 80/TCP) and renders one container per app entry.
- `service.yaml` reads each port's `service` block to determine exposure; if every port disables service creation it falls back to a dummy `80/TCP` entry so the manifest stays valid.
- `ingress.yaml` only renders when `.ingress.enabled` is true and hosts are defined; TLS secrets are named after the app and inherit the provided hosts.
- `namespace.yaml` creates the target namespace when `.Values.namespace.enabled` is set, otherwise Helm expects it to exist beforehand.

## Testing & Review Expectations

Treat `helm lint` as the minimum test. Augment with `helm template` runs that cover ingress enabled and disabled paths, multiple port definitions, and namespace creation. Before requesting review, capture the exact commands you ran along with any rendered manifest snippets that illustrate behavioral changes (new ports, hosts, TLS blocks, etc.).

## Commit & Pull Request Guidelines

Commits are short, imperative, and scoped to one logical change (Conventional Commit prefixes like `feat:` are OK). Describe new/changed value keys in the message body when relevant. PRs should link their tracking issue, summarize the chart changes, list the Helm commands executed (`lint`, `template`, and optional `upgrade --dry-run`), and attach rendered diffs when behavior shifts.

## Security & Configuration Tips

Never hard-code credentials—reference Kubernetes Secrets and only surface secret names in `values.yaml`. Keep RBAC minimal when additional manifests are introduced, and expose image tag/registry fields so operators can pin versions. Document any new knobs in the `values.yaml` comments so downstream teams understand how to opt into the behavior.

## Core Concept Reminder

`values.yaml` should stay business-focused: it captures service requirements (replicas, public URLs, exposed ports), and the Go templates translate those asks into Kubernetes manifests. When new requirements appear, shape the values to be human-readable first, then evolve the templates to honor them.

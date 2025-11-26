# Repository Guidelines

## Project Structure & Current State

The working chart lives under at the root dir and follows the standard Helm layout: `Chart.yaml` carries metadata, `values.yaml` contains the multi-app defaults, and `templates/` renders Kubernetes objects. The chart now supports defining **any number of apps** under `values.apps`, each with its own replica count, ports, service strategy, and ingress configuration—the etc. Keep helper files beside the templates they affect and prefer small, composable template snippets over large conditional blocks.

## Build, Test, and Validation Commands

Run Helm commands from this directory:

```sh
helm lint .
helm template . --values values.yaml
```

`helm lint` should pass before every commit. Use `helm template` (with any ad-hoc `values-<name>.yaml`) to verify rendering for new combinations, and finish with the dry-run upgrade command against the namespace you plan to target. Do not commit value files that contain secrets or personal overrides.

## Values Design & Coding Style

- `values.yaml` must read from a service-owner perspective: describe intent (apps, ingress needs, desired ports) and let the templates translate to Kubernetes structures. YAML uses two-space indentation and lowercase hyphenated keys. Template files rely on Go template trimming (`{{- ... -}}`) to keep manifests tidy. Favor boolean `enabled` flags for toggles (`apps.<name>.enabled`, `apps.<name>.ingress.enabled`, `namespace.enabled`) and name two-dimensional structures by what they configure (e.g., `ports[].service.nodePort`). Metadata names must remain DNS-1123 compliant; templates currently derive them from the entry's app key.

- When naming helper functions always start with `app-chart` to avoid collisisions. If the file is not called `_helper.tpl` then a second level prefix with the file name is recommended, e.g., `app-chart.ingress.my-function`.

- Always add a brief readme explaining the purpose of the helper function.
- Always use space to indent yaml files or any other files that accept space as indentation.

## Testing & Review Expectations

Treat `helm lint` and `helm template .` as the minimum test. Augment with `helm template` runs that cover ingress enabled and disabled paths, multiple port definitions, and namespace creation. Before requesting review, capture the exact commands you ran along with any rendered manifest snippets that illustrate behavioral changes (new ports, hosts, TLS blocks, etc.).

## Commit & Pull Request Guidelines

Commits are short, imperative, and scoped to one logical change (Conventional Commit prefixes like `feat:` are OK). Describe new/changed value keys in the message body when relevant. PRs should link their tracking issue, summarize the chart changes, list the Helm commands executed (`lint`, `template`, and optional `upgrade --dry-run`), and attach rendered diffs when behavior shifts.

## Core Concept Reminder

`values.yaml` should stay business-focused: it captures service requirements (replicas, public URLs, exposed ports), and the Go templates translate those asks into Kubernetes manifests. When new requirements appear, shape the values to be human-readable first, then evolve the templates to honor them.

# Repository Guidelines

## Project Structure & Current State

The repo now ships three sibling charts:

- `app-chart/` – original multi-app workload chart (main development focus).
- `meta-app-chart/` – placeholder application chart for future higher-level bundles.
- `library-app-chart/` – shared Helm library intended to centralize helpers.

`app-chart/` keeps the standard Helm layout: `Chart.yaml` carries metadata, `values.yaml` contains the multi-app defaults, and `templates/` renders Kubernetes objects. The chart supports defining **any number of apps** under `values.apps`, each with its own replica count, ports, service strategy, and ingress configuration. Keep helper files beside the templates they affect and prefer small, composable template snippets over large conditional blocks.

## Philosophy: Intent-Driven Configuration

The `app-chart` follows an **intent-driven** design pattern. The goal is to separate *what* the application needs (business intent) from *how* it is implemented in Kubernetes (technical realization).

- **Service-Owner Perspective:** `values.yaml` should be designed for a developer who knows their app's requirements (ports, URLs, dependencies) but shouldn't need to be an expert in Traefik CRDs, Network Policies, or complex Ingress annotations.
- **Abstraction over Raw CRDs:** Avoid exposing raw Kubernetes fields. Instead of requiring a Traefik `Middleware` CRD to be defined manually, provide intent-based keys like `ingress.middlewares.stripPrefix`.
- **Automatic Wiring:** The templates are responsible for the "glue." If a user expresses an intent (like stripping a prefix), the chart should automatically generate the necessary resources (Middlewares) and wire them (Annotations) without further user intervention.
- **Evolutionary Values:** When new technical requirements emerge, we first decide how to express that requirement as a simple, human-readable value, and then update the templates to honor that new "intent."

## Build, Test, and Validation Commands

Run Helm commands from within the chart you are testing. For the main chart:

```sh
cd app-chart
helm lint .
helm template . --values values.yaml
```

`helm lint` should pass before every commit. Use `helm template` (with any ad-hoc `values-<name>.yaml`) to verify rendering for new combinations, and finish with the dry-run upgrade command against the namespace you plan to target. Do not commit value files that contain secrets or personal overrides.

## Values Design & Coding Style

- `app-chart/values.yaml` must read from a service-owner perspective: describe intent (apps, ingress needs, desired ports) and let the templates translate to Kubernetes structures. YAML uses two-space indentation and lowercase hyphenated keys. Template files rely on Go template trimming (`{{- ... -}}`) to keep manifests tidy. Favor boolean `enabled` flags for toggles (`apps.<name>.enabled`, `apps.<name>.ingress.enabled`, `namespace.enabled`) and name two-dimensional structures by what they configure (e.g., `ports[].service.nodePort`). Metadata names must remain DNS-1123 compliant; templates currently derive them from the entry's app key.

- When naming helper functions always start with `app-chart` to avoid collisisions. If the file is not called `_helper.tpl` then a second level prefix with the file name is recommended, e.g., `app-chart.ingress.my-function`.

- Always add a brief readme explaining the purpose of the helper function.
- Always use space to indent yaml files or any other files that accept space as indentation.

## Testing & Review Expectations

Treat `helm lint` and `helm template .` (run from inside the target chart directory) as the minimum test. Augment with `helm template` runs that cover ingress enabled and disabled paths, multiple port definitions, and namespace creation. Before requesting review, capture the exact commands you ran along with any rendered manifest snippets that illustrate behavioral changes (new ports, hosts, TLS blocks, etc.).

## Commit & Pull Request Guidelines

Commits are short, imperative, and scoped to one logical change (Conventional Commit prefixes like `feat:` are OK). Describe new/changed value keys in the message body when relevant. PRs should link their tracking issue, summarize the chart changes, list the Helm commands executed (`lint`, `template`, and optional `upgrade --dry-run`), and attach rendered diffs when behavior shifts.

## Core Concept Reminder

`app-chart/values.yaml` should stay business-focused: it captures service requirements (replicas, public URLs, exposed ports), and the Go templates translate those asks into Kubernetes manifests. When new requirements appear, shape the values to be human-readable first, then evolve the templates to honor them.

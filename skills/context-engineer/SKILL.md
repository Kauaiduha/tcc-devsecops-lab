---
name: context-engineer
description: Use this skill when you need to initialize or maintain a persistent project memory system inside the current repository, including discovery of the real stack, architecture mapping, MEMORY.md updates, tasks indexes, and session workflows such as /context-load and /context-manager.
---

# Context Engineer

## Overview

Use this skill to turn the current repository into a filesystem-backed "second brain". It is meant for onboarding, session recovery, and long-running project continuity.

This skill is especially useful when the repo has sparse documentation, partial infrastructure, or no reliable git history. It forces discovery from real files before writing memory.

## Workflow

### 1. Discover before writing

Inspect the repository and record only what is actually present:

- Stack: languages, runtime, deployment tooling, databases, CI/CD, infra
- Architecture: where handlers, services, models, frontend, manifests, scripts, docs, and workflows live
- Project objective: prefer `README.md`; if absent, infer carefully from filenames and directory structure
- Current status: use git history if the repo is valid; otherwise use file mtimes, recent logs, active manifests, and operational evidence

Do not invent missing layers. If there is no backend or frontend source in the repo, say so explicitly.

### 2. Initialize the memory filesystem

Create or update these files in the repo root:

- `MEMORY.md`
- `tasks/_INDEX.md`
- `tasks/knowledge/`
- `tasks/plans/`

`MEMORY.md` should contain:

- Current project summary
- Detected stack and architecture
- Important operational decisions
- Current delivery/status
- Known gaps, risks, and pending work

`tasks/_INDEX.md` should map business or technical flows to concrete file paths in the repo. In infra-heavy repos, flows can be things like cluster bootstrap, app deployment, ingress exposure, security hardening, CI/CD, or runtime monitoring.

### 3. Maintain session workflows

Ensure there is a local workflow directory. Prefer `.agent/workflows/`. If the repo already uses another agent convention, follow that instead.

Create or update:

- `.agent/workflows/context-load.md`
- `.agent/workflows/context-manager.md`

`context-load` should instruct the agent to read:

- `MEMORY.md`
- `tasks/_INDEX.md`
- the most recent entries in `tasks/knowledge/`
- any active plan files in `tasks/plans/`

`context-manager` should instruct the agent to:

- compare current repo state with `MEMORY.md`
- update the status summary
- add a dated knowledge note when a reusable lesson was learned
- register new plans when a design or migration starts

### 4. Write dated knowledge notes

When creating knowledge notes, use `tasks/knowledge/YYYY-MM-DD-topic.md`.

Keep them short and reusable:

- what changed
- why it mattered
- validation evidence
- pitfalls or constraints

### 5. Validation rules

Before declaring the memory system active, verify:

- required files exist
- the files reference real paths
- the summary matches the current repository contents
- any missing README or broken git repo is explicitly documented

## Project-specific guidance for this repository

At the time this skill was created, this repo is a Kubernetes lab for deploying OWASP Juice Shop in a local cluster:

- manifests under `k8s/juice-shop/`
- operational log in `minikube_logs.txt`
- no application source code or `README.md`
- current local runtime evidence points to Minikube
- the TCC roadmap is a first-class project artifact and should be persisted under `docs/` or `tasks/plans/`
- OWASP Juice Shop should be documented as an intentionally vulnerable sample application used for security validation, not as custom business software

For this repo, architecture mapping should emphasize infrastructure rather than MVC layers.

# MEMORY

## Project Snapshot

- Repository purpose: local Kubernetes lab for a TCC/DevSecOps project centered on deploying OWASP Juice Shop and evolving the environment across later phases such as CI/CD, WAF, and runtime security.
- Current scope in this repository: infrastructure manifests, local agent memory/workflows, a TCC roadmap document, and the base assets for Entrega 2 CI/CD are present.
- Functional role of the target app: OWASP Juice Shop is an intentionally vulnerable example application maintained by OWASP and used here as the attack target and validation surface for Shift Left and Shield Right controls.
- Documentation status: `README.md` is absent.
- VCS status: a `.git/` directory exists but is not a valid git repository from this path, so git history could not be used as a reliable source of project status.

## Detected Stack

- Infrastructure as code: Kubernetes manifests in YAML
- Application image: `bkimminich/juice-shop:latest`
- Local cluster/runtime evidence: Minikube
- Ingress layer: NGINX Ingress Controller
- Package/deploy tool evidence: Helm was used operationally for ingress installation, inferred from the live cluster validation and chart labels
- Language/framework/application source: not present in this repository
- Database source/configuration: not present in this repository
- CI/CD configuration: present via GitHub Actions workflow, SonarQube properties, pipeline notes, and a local Trivy helper script

## TCC Roadmap

The working plan provided for the TCC covers these milestones:

- Entrega 0: cronograma, escopo, estrutura inicial do repositório e ferramentas locais
- Entrega 1: cluster Kubernetes funcional com Juice Shop acessível
- Entrega 2: pipeline CI/CD com build, SonarQube, Trivy, push e gate de segurança
- Entrega 3: WAF no cluster com ModSecurity ou Coraza
- Entrega 4: runtime security com Falco e Falcosidekick
- Entrega 5: simulação de ataques para demonstrar complementaridade entre Shift Left e Shield Right
- Entrega 6: análise comparativa, diagramas e documentação técnica reproduzível
- Entrega 7: validação final, organização do repositório e entrega da PoC

## Detected Architecture

This repo is infra-centric, not an application monorepo.

- App deployment manifest: [k8s/juice-shop/deployment.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/deployment.yaml:1)
- Internal service exposure: [k8s/juice-shop/service.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/service.yaml:1)
- External HTTP routing: [k8s/juice-shop/ingress.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/ingress.yaml:1)
- Cluster bootstrap evidence/logging: [minikube_logs.txt](/l/disk0/kauaidb/TCC%20POC/minikube_logs.txt:1)

There are currently no handlers, services, models, frontend source folders, tests, or CI workflow files in the repository.
There are currently no handlers, services, models, frontend source folders, or tests in the repository. CI workflow files are now present.

- CI workflow: [/.github/workflows/devsecops.yml](/l/disk0/kauaidb/TCC%20POC/.github/workflows/devsecops.yml:1)
- Sonar config: [sonar-project.properties](/l/disk0/kauaidb/TCC%20POC/sonar-project.properties:1)
- Pipeline notes: [pipeline/README.md](/l/disk0/kauaidb/TCC%20POC/pipeline/README.md:1)
- Local scan helper: [scripts/run-trivy-local.sh](/l/disk0/kauaidb/TCC%20POC/scripts/run-trivy-local.sh:1)
- TCC roadmap: [docs/tcc-roadmap.md](/l/disk0/kauaidb/TCC%20POC/docs/tcc-roadmap.md:1)
- Secrets setup guide: [docs/secrets-setup.md](/l/disk0/kauaidb/TCC%20POC/docs/secrets-setup.md:1)

## Architecture Decisions Observed

- Local runtime choice in practice: Minikube
- Dedicated namespace in use: `devsecops-lab`
- Juice Shop is exposed internally via `ClusterIP` on port `3000`
- HTTP ingress is routed with class `nginx`
- The deployment defines CPU and memory requests/limits
- The deployment defines readiness and liveness probes against `/` on port `3000`

## Current Status

Based on live cluster validation performed on 2026-05-16:

- Minikube was running and API server was reachable
- Namespace `devsecops-lab` existed and was active
- `ingress-nginx-controller` was `1/1 Running`
- `juice-shop` was `1/1 Running`
- `kubectl get all -n devsecops-lab` showed both deployments available
- HTTP validation against the ingress path returned `200 OK`

This means the technical implementation for the first delivery milestone appears operational at the time of the last validation.

## Known Gaps

- No `README.md` describing setup, objective, or operating commands
- No committed evidence files for the TCC deliverables such as browser screenshots
- No WAF manifests/configuration yet
- No Falco/Falcosidekick manifests/configuration yet
- No written justification document for the local runtime choice in this repository
- The Sonar stage is structurally ready but depends on GitHub secrets and a real SonarQube or SonarCloud project
- The SonarCloud project key in use is `Kauaiduha_tcc-devsecops-lab`
- The pipeline currently builds a wrapper image because the Juice Shop source code is not versioned in this repository
- Local secret file templates now exist, but the real credential files are not expected to be committed

## Pending Work

- Add written runtime justification for Minikube
- Capture and store evidence for Entrega 1
- Configure `SONAR_TOKEN` and `SONAR_HOST_URL` in GitHub for Entrega 2
- Run and validate the CI/CD pipeline in GitHub Actions
- Add a deliberate vulnerable dependency or controlled failing condition to demonstrate a blocked pipeline
- Add WAF configuration for Entrega 3
- Add Falco runtime security assets for Entrega 4
- Consolidate the TCC roadmap into repository documentation

## Operating Assumptions

- When project status must be inferred, prefer filesystem evidence and live cluster state over git history because git is currently unavailable from this repo path
- When a future session starts, reload this file first, then `tasks/_INDEX.md`, then the latest knowledge notes

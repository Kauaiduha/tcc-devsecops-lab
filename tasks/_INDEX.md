# Task Index

## Primary Flows

### 1. Cluster bootstrap and runtime evidence

- Minikube operational log: [minikube_logs.txt](/l/disk0/kauaidb/TCC%20POC/minikube_logs.txt:1)
- Purpose: inspect local cluster startup evidence and historical Minikube activity

### 2. Juice Shop deployment

- Deployment manifest: [k8s/juice-shop/deployment.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/deployment.yaml:1)
- Purpose: container image, replica count, resource requests/limits, liveness and readiness probes

### 3. Internal service exposure

- Service manifest: [k8s/juice-shop/service.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/service.yaml:1)
- Purpose: expose Juice Shop inside the cluster on port `3000` using `ClusterIP`

### 4. External HTTP entrypoint

- Ingress manifest: [k8s/juice-shop/ingress.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/ingress.yaml:1)
- Purpose: route `juice-shop.local` traffic to the Juice Shop service through NGINX Ingress

## Delivery Mapping

### Entrega 1: Ambiente K8s Base Funcional

- Cluster/runtime evidence: [minikube_logs.txt](/l/disk0/kauaidb/TCC%20POC/minikube_logs.txt:1)
- App deployment: [k8s/juice-shop/deployment.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/deployment.yaml:1)
- Service exposure: [k8s/juice-shop/service.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/service.yaml:1)
- Ingress routing: [k8s/juice-shop/ingress.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/ingress.yaml:1)

### Entrega 2: Pipeline CI/CD com Shift Left

- Workflow: [/.github/workflows/devsecops.yml](/l/disk0/kauaidb/TCC%20POC/.github/workflows/devsecops.yml:1)
- Sonar config: [sonar-project.properties](/l/disk0/kauaidb/TCC%20POC/sonar-project.properties:1)
- Build asset: [Dockerfile](/l/disk0/kauaidb/TCC%20POC/Dockerfile:1)
- Local validation helper: [scripts/run-trivy-local.sh](/l/disk0/kauaidb/TCC%20POC/scripts/run-trivy-local.sh:1)
- Pipeline notes: [pipeline/README.md](/l/disk0/kauaidb/TCC%20POC/pipeline/README.md:1)
- Delivery record: [docs/entrega-2-shift-left.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-2-shift-left.md:1)

### Entrega 3: WAF no Cluster

- Controller values: [waf/ingress-nginx-modsecurity-values.yaml](/l/disk0/kauaidb/TCC%20POC/waf/ingress-nginx-modsecurity-values.yaml:1)
- Lab rules: [waf/modsecurity-config.conf](/l/disk0/kauaidb/TCC%20POC/waf/modsecurity-config.conf:1)
- Apply guide: [waf/README.md](/l/disk0/kauaidb/TCC%20POC/waf/README.md:1)
- Validation helper: [scripts/test-waf.sh](/l/disk0/kauaidb/TCC%20POC/scripts/test-waf.sh:1)
- Architectural decision: [docs/entrega-3-waf-decisao-arquitetural.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-3-waf-decisao-arquitetural.md:1)
- Validation record: [docs/entrega-3-waf-validacao.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-3-waf-validacao.md:1)
- Evidence guide: [docs/entrega-3-evidencias.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-3-evidencias.md:1)

### Entrega 4: Runtime Security

- Custom rules: [falco/custom-rules.yaml](/l/disk0/kauaidb/TCC%20POC/falco/custom-rules.yaml:1)
- Helm values: [falco/falco-values.yaml](/l/disk0/kauaidb/TCC%20POC/falco/falco-values.yaml:1)
- Apply guide: [falco/README.md](/l/disk0/kauaidb/TCC%20POC/falco/README.md:1)
- Validation helper: [scripts/test-falco.sh](/l/disk0/kauaidb/TCC%20POC/scripts/test-falco.sh:1)
- Delivery record: [docs/entrega-4-runtime-security.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-4-runtime-security.md:1)

## Context Files

- Current memory: [MEMORY.md](/l/disk0/kauaidb/TCC%20POC/MEMORY.md:1)
- Knowledge notes: `tasks/knowledge/`
- Design plans: `tasks/plans/`
- Session workflows: `.agent/workflows/`

## Roadmap and Reference

- TCC roadmap and deliverables: [docs/tcc-roadmap.md](/l/disk0/kauaidb/TCC%20POC/docs/tcc-roadmap.md:1)

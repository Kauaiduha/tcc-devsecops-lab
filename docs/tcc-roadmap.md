# TCC DevSecOps Lab Roadmap

## Target Application

The target application used throughout this TCC is OWASP Juice Shop.

- It is an intentionally vulnerable example web application maintained by OWASP.
- It is suitable for academic and practical security validation because it contains realistic vulnerability classes and has a public Docker image.
- In this project it serves as:
  - the workload deployed in Kubernetes
  - the target scanned by Shift Left controls
  - the target protected by Shield Right controls
  - the target used in attack simulations

## Milestones

### Entrega 0

- Define the schedule with the advisor
- Align scope and future-work boundaries
- Initialize the repository structure
- Install local tooling: `kubectl`, `helm`, `docker`, and a local Kubernetes runtime

### Entrega 1

- Run Juice Shop in the local Kubernetes cluster
- Use a dedicated namespace: `devsecops-lab`
- Deploy `Deployment`, `Service`, and `Ingress`
- Install NGINX Ingress Controller
- Validate browser access and collect evidence

### Entrega 2

- Build a Docker image for the workload
- Run SAST with SonarQube or SonarCloud
- Run SCA and image scanning with Trivy
- Break the pipeline when security gates fail
- Push the image only after passing the gates
- Optionally deploy manifests to Kubernetes

### Entrega 3

- Add a WAF layer before the application
- Prefer NGINX Ingress with ModSecurity for the simplest path
- Validate SQL Injection and XSS blocking
- Collect HTTP 403 and WAF log evidence

### Entrega 4

- Install Falco and Falcosidekick
- Add custom rules for Juice Shop
- Trigger shell execution and sensitive file access from inside the container
- Collect runtime alerts

### Entrega 5

- Compare Shift Left and Shield Right across attack scenarios
- Show at least one case blocked in the pipeline
- Show at least one case blocked at the edge
- Show at least one case detected at runtime

### Entrega 6

- Consolidate evidence, metrics, and architecture diagrams
- Write reproducible documentation
- Explain detection coverage and limitations

### Entrega 7

- Recreate the environment from zero using the project documentation
- Organize the final repository layout
- Produce the final deliverables for the advisor

# Secrets Setup

## Files to create

Create the real local files from these templates:

- `secrets/devsecops.env` from `secrets/devsecops.env.example`
- `secrets/kubeconfig` from `secrets/kubeconfig.example` only if you want a dedicated kubeconfig copy for automation

These real files are ignored by git.

## 1. SonarQube or SonarCloud

Fill these fields in `secrets/devsecops.env`:

- `SONAR_HOST_URL`
- `SONAR_TOKEN`
- `SONAR_PROJECT_KEY`

How to fill:

- If you use SonarCloud:
  - `SONAR_HOST_URL=https://sonarcloud.io`
  - `SONAR_TOKEN`: create a user token in SonarCloud
  - `SONAR_PROJECT_KEY`: the project key created in SonarCloud

- If you use local SonarQube:
  - `SONAR_HOST_URL=http://<host>:9000` or `http://localhost:9000`
  - `SONAR_TOKEN`: create a token in SonarQube
  - `SONAR_PROJECT_KEY`: the project key you configured there

## 2. Container registry

Fill these fields in `secrets/devsecops.env`:

- `REGISTRY`
- `REGISTRY_IMAGE`
- `REGISTRY_USER`
- `REGISTRY_PASSWORD`

Recommended GHCR example:

- `REGISTRY=ghcr.io`
- `REGISTRY_IMAGE=ghcr.io/<seu-usuario-ou-org>/juice-shop-lab`
- `REGISTRY_USER=<seu-usuario-github>`
- `REGISTRY_PASSWORD=<seu-token>`

For GHCR, the password should be a GitHub token with package write permission if you are going to push outside GitHub Actions.

## 3. GitHub repository info

Fill these fields in `secrets/devsecops.env`:

- `GITHUB_REPOSITORY`
- `GITHUB_DEFAULT_BRANCH`

Example:

- `GITHUB_REPOSITORY=seu-usuario/tcc-devsecops-lab`
- `GITHUB_DEFAULT_BRANCH=main`

## 4. Kubernetes settings

Fill these fields in `secrets/devsecops.env`:

- `K8S_NAMESPACE`
- `K8S_INGRESS_HOST`

For your current lab, the expected values are:

- `K8S_NAMESPACE=devsecops-lab`
- `K8S_INGRESS_HOST=juice-shop.local`

## 5. Optional kubeconfig copy

If you want me to use a project-local kubeconfig file:

1. Copy your current kubeconfig to `secrets/kubeconfig`
2. Keep it local only
3. Tell me to use that file in the next step

If you do not create it, I can continue using your default local kube context whenever cluster access is available.

## 6. GitHub Actions secrets

The local `secrets/devsecops.env` helps with local work and documenting the expected values, but GitHub Actions still needs repository secrets configured in GitHub.

You will need at least:

- `SONAR_TOKEN`
- `SONAR_HOST_URL`

Depending on how you publish images, you may also need registry-specific secrets if you do not rely on `GITHUB_TOKEN`.

## Minimal example

Example `secrets/devsecops.env`:

```dotenv
SONAR_HOST_URL=https://sonarcloud.io
SONAR_TOKEN=your_real_token_here
SONAR_PROJECT_KEY=Kauaiduha_tcc-devsecops-lab
REGISTRY=ghcr.io
REGISTRY_IMAGE=ghcr.io/Kauaiduha/juice-shop-lab
REGISTRY_USER=Kauaiduha
REGISTRY_PASSWORD=seu_token
GITHUB_REPOSITORY=Kauaiduha/tcc-devsecops-lab
GITHUB_DEFAULT_BRANCH=main
K8S_NAMESPACE=devsecops-lab
K8S_INGRESS_HOST=juice-shop.local
ENABLE_CI_DEPLOY=false
```

## After you fill it

After you create `secrets/devsecops.env`, tell me one of these:

- `preenchi o devsecops.env`
- `preenchi o devsecops.env e o kubeconfig`

Then I can do the next steps:

- align the workflow with your real registry/project values
- prepare the failing security test for Entrega 2
- add safer local helper scripts
- prepare the GitHub Actions checklist for execution

# Pipeline Notes

## Scope

This directory documents the CI/CD assets for Entrega 2.

The repository does not currently contain custom application source code, so the pipeline is based on a minimal wrapper image:

- `Dockerfile` builds from `bkimminich/juice-shop:latest`
- SonarQube analyzes the repository content that exists today
- Trivy scans both the filesystem and the built image

## Required GitHub Secrets

- `SONAR_TOKEN`

## Required GitHub Variables or Secrets

- `SONAR_HOST_URL`

For SonarQube Cloud, use:

- `SONAR_HOST_URL=https://sonarcloud.io`

This project also uses:

- `sonar.projectKey=Kauaiduha_tcc-devsecops-lab`
- `sonar.organization=kauaiduha`

## Current Behavior

- `build` creates the image and stores it as an artifact
- `sast` runs SonarQube scan plus quality gate
- `sca` runs Trivy on the repository and on the Docker image
- `push` publishes to GHCR only if all prior jobs pass
- `deploy` is intentionally disabled until cluster credentials are added

## Important Limitation

Because this repository does not contain the Juice Shop source code itself, the SAST stage validates repository assets and pipeline configuration rather than custom business code. If custom code is added later, `sonar.sources` and the Docker build context should be refined accordingly.

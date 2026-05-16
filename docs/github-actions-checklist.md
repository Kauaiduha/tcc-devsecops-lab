# GitHub Actions Checklist

## Required before first pipeline run

In the GitHub repository `Kauaiduha/tcc-devsecops-lab`:

### Secrets

Add these in `Settings -> Secrets and variables -> Actions -> Secrets`:

- `SONAR_TOKEN`

### Variables

Add these in `Settings -> Secrets and variables -> Actions -> Variables`:

- `SONAR_HOST_URL=https://sonarcloud.io`

## Expected workflow behavior

- `build`: builds the wrapper image
- `sast`: sends analysis to SonarQube Cloud and waits for the quality gate
- `sca`: runs Trivy on filesystem and image
- `push`: pushes to GHCR only if previous jobs succeed

## Important note

`SONAR_HOST_URL` is still empty in the local `secrets/devsecops.env` until you set it yourself. The correct value for SonarQube Cloud is:

```dotenv
SONAR_HOST_URL=https://sonarcloud.io
```

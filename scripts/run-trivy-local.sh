#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="${1:-juice-shop-lab:local}"

docker build -t "${IMAGE_REF}" .
trivy fs . --severity HIGH,CRITICAL --exit-code 1
trivy image "${IMAGE_REF}" --severity HIGH,CRITICAL --exit-code 1

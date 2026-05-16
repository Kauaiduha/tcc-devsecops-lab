#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="${1:-juice-shop-lab:local}"
CACHE_DIR="${TRIVY_CACHE_DIR:-.cache/trivy}"

docker build -t "${IMAGE_REF}" .
mkdir -p "${CACHE_DIR}"
trivy fs . --cache-dir "${CACHE_DIR}" --severity HIGH,CRITICAL --exit-code 1
trivy image "${IMAGE_REF}" --cache-dir "${CACHE_DIR}" --severity HIGH,CRITICAL --exit-code 1

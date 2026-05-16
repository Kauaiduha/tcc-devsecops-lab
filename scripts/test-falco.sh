#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-devsecops-lab}"
POD_NAME="${2:-$(kubectl get pods -n "${NAMESPACE}" -l app=juice-shop -o jsonpath='{.items[0].metadata.name}')}"
NODE_BIN="${3:-/nodejs/bin/node}"
WAIT_SECONDS="${4:-3}"
FALCO_SINCE="${5:-30s}"
FALCO_FILTER='Exec detectado|Leitura de arquivo sensivel|juice-shop|/etc/passwd|passwd-read-test|exec-test'
FALCO_FALLBACK_SINCE="${6:-5m}"

echo "Triggering shell execution in pod ${POD_NAME}"
kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- "${NODE_BIN}" -e 'console.log("exec-test")'

echo
echo "Triggering sensitive file read in pod ${POD_NAME}"
kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- "${NODE_BIN}" -e 'require("fs").readFileSync("/etc/passwd","utf8"); console.log("passwd-read-test")'

echo
echo "Waiting ${WAIT_SECONDS}s for Falco to process the events"
sleep "${WAIT_SECONDS}"

echo
echo "Recent Falco alerts"
FALCO_LOGS="$(kubectl logs daemonset/falco -n "${NAMESPACE}" --since="${FALCO_SINCE}" 2>/dev/null || true)"
if printf '%s\n' "${FALCO_LOGS}" | grep -E "${FALCO_FILTER}" >/dev/null 2>&1; then
  printf '%s\n' "${FALCO_LOGS}" | grep -E "${FALCO_FILTER}"
else
  echo "No filtered Falco alerts found in the last ${FALCO_SINCE}. Retrying with ${FALCO_FALLBACK_SINCE}."
  FALCO_FALLBACK_LOGS="$(kubectl logs daemonset/falco -n "${NAMESPACE}" --since="${FALCO_FALLBACK_SINCE}" 2>/dev/null || true)"
  if printf '%s\n' "${FALCO_FALLBACK_LOGS}" | grep -E "${FALCO_FILTER}" >/dev/null 2>&1; then
    printf '%s\n' "${FALCO_FALLBACK_LOGS}" | grep -E "${FALCO_FILTER}"
  else
    echo "No matching Falco alerts found even in the last ${FALCO_FALLBACK_SINCE}."
  fi
fi

echo
echo "Recent Falcosidekick logs"
kubectl logs deployment/falco-falcosidekick -n "${NAMESPACE}" --since="${FALCO_SINCE}" || true

#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-}"
REPETITIONS="${2:-10}"
RUN_DIR="${3:-docs/demo-output/run-$(date +%Y%m%d-%H%M%S)}"

if [[ "$SCENARIO" != "waf" && "$SCENARIO" != "falco" && "$SCENARIO" != "all" ]]; then
  echo "Usage: $0 <waf|falco|all> [repetitions] [output-dir]" >&2
  exit 2
fi

mkdir -p "$RUN_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAF_DIR="$RUN_DIR/waf"
FALCO_DIR="$RUN_DIR/falco"

# Capture the effective Kubernetes configuration, rather than trusting a stale UI state file.
kubectl_cmd=(kubectl)
if [[ -n "${KUBECTL_CONTEXT:-}" ]]; then
  kubectl_cmd+=(--context="$KUBECTL_CONTEXT")
fi
enforcement="$("${kubectl_cmd[@]}" get ingress juice-shop -n devsecops-lab -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/enable-modsecurity}' 2>/dev/null || true)"
if [[ "$enforcement" == "true" ]]; then
  profile_mode="defendido"
  profile_description="Perfil defendido: ModSecurity e OWASP CRS em enforcement no Ingress do Juice Shop."
elif [[ "$enforcement" == "false" ]]; then
  profile_mode="baseline"
  profile_description="Baseline controlado: WAF sem enforcement no Ingress do Juice Shop."
elif [[ -f "docs/demo-output/lab-profile.json" ]]; then
  cp "docs/demo-output/lab-profile.json" "$RUN_DIR/lab-profile.json"
  profile_mode=""
else
  profile_mode=""
fi

if [[ -n "$profile_mode" ]]; then
  node - "$RUN_DIR/lab-profile.json" "$profile_mode" "$profile_description" <<'NODE'
const fs = require('fs');
const [file, mode, description] = process.argv.slice(2);
fs.writeFileSync(file, `${JSON.stringify({ mode, description, capturedAt: new Date().toISOString() }, null, 2)}\n`);
NODE
fi

if [[ "$SCENARIO" == "waf" || "$SCENARIO" == "all" ]]; then
  "$SCRIPT_DIR/collect-waf-evidence.sh" "$REPETITIONS" "$WAF_DIR"
fi

if [[ "$SCENARIO" == "falco" || "$SCENARIO" == "all" ]]; then
  "$SCRIPT_DIR/collect-falco-evidence.sh" "$REPETITIONS" "$FALCO_DIR"
fi

if [[ "$SCENARIO" == "all" ]]; then
  "$SCRIPT_DIR/consolidate-evidence.sh" "$WAF_DIR/waf-resultados.csv" "$FALCO_DIR/falco-resultados.csv" "$RUN_DIR/resumo.md"
fi

node "$SCRIPT_DIR/generate-dashboard-data.mjs" "$RUN_DIR" "$RUN_DIR/dashboard-data.json"

echo "Evidence run completed: $RUN_DIR"
echo "Dashboard data: $RUN_DIR/dashboard-data.json"

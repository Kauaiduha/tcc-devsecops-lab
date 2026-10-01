#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-}"
NAMESPACE="${LAB_NAMESPACE:-devsecops-lab}"
KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-}"
OUTPUT_FILE="${LAB_PROFILE_FILE:-docs/demo-output/lab-profile.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "$PROFILE" != "baseline" && "$PROFILE" != "defendido" ]]; then
  echo "Usage: $0 <baseline|defendido>" >&2
  exit 2
fi

kubectl_cmd=(kubectl)
if [[ -n "$KUBECTL_CONTEXT" ]]; then
  kubectl_cmd+=(--context="$KUBECTL_CONTEXT")
fi

case "$PROFILE" in
  baseline)
    # The controller remains installed; this disables enforcement only for this lab Ingress.
    "${kubectl_cmd[@]}" annotate ingress juice-shop -n "$NAMESPACE" \
      nginx.ingress.kubernetes.io/enable-modsecurity="false" \
      nginx.ingress.kubernetes.io/enable-owasp-core-rules="false" \
      --overwrite
    DESCRIPTION="Baseline controlado: WAF em observacao, sem bloquear o trafego do Juice Shop."
    ;;
  defendido)
    "${kubectl_cmd[@]}" apply -f "$ROOT_DIR/k8s/juice-shop/ingress.yaml"
    DESCRIPTION="Perfil defendido: ModSecurity e OWASP CRS em enforcement no Ingress do Juice Shop."
    ;;
esac

mkdir -p "$(dirname "$OUTPUT_FILE")"
node - "$OUTPUT_FILE" "$PROFILE" "$DESCRIPTION" <<'NODE'
const fs = require('fs');
const [file, mode, description] = process.argv.slice(2);
fs.writeFileSync(file, `${JSON.stringify({ mode, description, changedAt: new Date().toISOString() }, null, 2)}\n`);
NODE

echo "$DESCRIPTION"
echo "Aguarde alguns segundos para o NGINX recarregar a configuracao."
sleep "${WAF_RELOAD_WAIT_SECONDS:-3}"

#!/usr/bin/env bash
set -euo pipefail

REPETITIONS="${1:-10}"
OUTPUT_DIR="${2:-docs/demo-output/waf-$(date +%Y%m%d-%H%M%S)}"
HOST_HEADER="${POC_HOST:-juice-shop.local}"
KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-}"

if ! [[ "$REPETITIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [repetitions] [output-dir]" >&2
  exit 2
fi

kubectl_cmd=(kubectl)
if [[ -n "$KUBECTL_CONTEXT" ]]; then
  kubectl_cmd+=(--context="$KUBECTL_CONTEXT")
fi

if [[ -n "${POC_BASE_URL:-}" ]]; then
  BASE_URL="$POC_BASE_URL"
else
  NODE_IP="$(minikube ip)"
  NODE_PORT="$("${kubectl_cmd[@]}" get svc ingress-nginx-controller -n devsecops-lab -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')"
  BASE_URL="http://${NODE_IP}:${NODE_PORT}"
fi

mkdir -p "$OUTPUT_DIR"
CSV_FILE="$OUTPUT_DIR/waf-resultados.csv"
LOG_FILE="$OUTPUT_DIR/waf-modsecurity.log"
BODY_DIR="$OUTPUT_DIR/respostas"
START_UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"

mkdir -p "$BODY_DIR"
printf 'data_hora,cenario,iteracao,http_code,time_total_s,response_bytes\n' > "$CSV_FILE"

request() {
  local scenario="$1"
  local iteration="$2"
  local result timestamp body_file
  body_file="$BODY_DIR/${scenario}-${iteration}.body"

  case "$scenario" in
    sqli)
      result="$(curl --get -sS -o "$body_file" -w '%{http_code},%{time_total},%{size_download}' -H "Host: $HOST_HEADER" --data-urlencode "q=test' OR 1=1--" "$BASE_URL/rest/products/search" || true)"
      ;;
    xss)
      result="$(curl --get -sS -o "$body_file" -w '%{http_code},%{time_total},%{size_download}' -H "Host: $HOST_HEADER" --data-urlencode 'q=<script>alert(1)</script>' "$BASE_URL/search" || true)"
      ;;
    benign_root)
      result="$(curl -sS -o "$body_file" -w '%{http_code},%{time_total},%{size_download}' -H "Host: $HOST_HEADER" "$BASE_URL/" || true)"
      ;;
    benign_search)
      result="$(curl --get -sS -o "$body_file" -w '%{http_code},%{time_total},%{size_download}' -H "Host: $HOST_HEADER" --data-urlencode 'q=apple juice' "$BASE_URL/rest/products/search" || true)"
      ;;
  esac

  timestamp="$(date --iso-8601=seconds)"
  printf '%s,%s,%d,%s\n' "$timestamp" "$scenario" "$iteration" "$result" >> "$CSV_FILE"
}

echo "Collecting WAF evidence against $BASE_URL ($REPETITIONS repetitions per scenario)"
for scenario in sqli xss benign_root benign_search; do
  for iteration in $(seq 1 "$REPETITIONS"); do
    request "$scenario" "$iteration"
  done
done

"${kubectl_cmd[@]}" logs deployment/ingress-nginx-controller -n devsecops-lab --since-time="$START_UTC" 2>/dev/null \
  | grep -E 'ModSecurity: Access denied|GET ' > "$LOG_FILE" || true

echo "WAF CSV: $CSV_FILE"
echo "WAF logs: $LOG_FILE"

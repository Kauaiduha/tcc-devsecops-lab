#!/usr/bin/env bash
set -euo pipefail

REPETITIONS="${1:-10}"
OUTPUT_DIR="${2:-docs/demo-output/falco-$(date +%Y%m%d-%H%M%S)}"
WAIT_SECONDS="${FALCO_WAIT_SECONDS:-5}"
NAMESPACE="${FALCO_NAMESPACE:-devsecops-lab}"
NODE_BIN="${FALCO_NODE_BIN:-/nodejs/bin/node}"
KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-}"

if ! [[ "$REPETITIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [repetitions] [output-dir]" >&2
  exit 2
fi

kubectl_cmd=(kubectl)
if [[ -n "$KUBECTL_CONTEXT" ]]; then
  kubectl_cmd+=(--context="$KUBECTL_CONTEXT")
fi

POD_NAME="$("${kubectl_cmd[@]}" get pods -n "$NAMESPACE" -l app=juice-shop -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$POD_NAME" ]]; then
  echo "Juice Shop pod not found in namespace $NAMESPACE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
STARTS_FILE="$OUTPUT_DIR/falco-disparos.csv"
RAW_LOG_FILE="$OUTPUT_DIR/falco-alertas.jsonl"
SIDEKICK_LOG_FILE="$OUTPUT_DIR/falcosidekick.log"
CSV_FILE="$OUTPUT_DIR/falco-resultados.csv"
START_UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"

printf 'cenario,iteracao,marcador,disparo_utc\n' > "$STARTS_FILE"

echo "Collecting Falco evidence in pod $POD_NAME ($REPETITIONS repetitions per scenario)"
for iteration in $(seq 1 "$REPETITIONS"); do
  marker="$(printf 'falco-exec-C5-%02d' "$iteration")"
  started="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
  "${kubectl_cmd[@]}" exec -n "$NAMESPACE" "$POD_NAME" -- "$NODE_BIN" -e "console.log('$marker')" >/dev/null
  printf 'C5,%d,%s,%s\n' "$iteration" "$marker" "$started" >> "$STARTS_FILE"

  marker="$(printf 'falco-read-C6-%02d' "$iteration")"
  started="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
  "${kubectl_cmd[@]}" exec -n "$NAMESPACE" "$POD_NAME" -- "$NODE_BIN" -e "require('fs').readFileSync('/etc/passwd','utf8'); console.log('$marker')" >/dev/null
  printf 'C6,%d,%s,%s\n' "$iteration" "$marker" "$started" >> "$STARTS_FILE"
done

echo "Waiting ${WAIT_SECONDS}s for Falco to process the events"
sleep "$WAIT_SECONDS"

"${kubectl_cmd[@]}" logs daemonset/falco -n "$NAMESPACE" --since-time="$START_UTC" 2>/dev/null > "$RAW_LOG_FILE" || true
"${kubectl_cmd[@]}" logs deployment/falco-falcosidekick -n "$NAMESPACE" --since-time="$START_UTC" > "$SIDEKICK_LOG_FILE" 2>&1 || true

node - "$STARTS_FILE" "$RAW_LOG_FILE" "$CSV_FILE" "$POD_NAME" "$NAMESPACE" <<'NODE'
const fs = require('fs');
const [startsPath, logsPath, outputPath, pod, namespace] = process.argv.slice(2);
const starts = fs.readFileSync(startsPath, 'utf8').trim().split('\n').slice(1).map((line) => {
  const [scenario, iteration, marker, started] = line.split(',');
  return { scenario, iteration, marker, started };
});
const expectedRule = (scenario) => scenario === 'C5' ? 'Exec into Juice Shop' : 'Read sensitive file in Juice Shop';
const alerts = new Map();
for (const line of fs.readFileSync(logsPath, 'utf8').trim().split('\n')) {
  try {
    const event = JSON.parse(line);
    for (const start of starts) {
      if (event.rule === expectedRule(start.scenario) && (event.output || '').includes(start.marker) && !alerts.has(start.marker)) {
        alerts.set(start.marker, event);
      }
    }
  } catch (_) {
    // Falco startup lines are not JSON and are irrelevant to this collection.
  }
}
function toNanoseconds(iso) {
  const match = iso.match(/^(.*?)(?:\.(\d+))?Z$/);
  const milliseconds = BigInt(Date.parse(`${match[1]}Z`));
  const fractional = BigInt((match[2] || '').padEnd(9, '0').slice(0, 9));
  return milliseconds * 1000000n + fractional;
}
const rows = ['cenario,iteracao,marcador,disparo_utc,alerta_utc,regra_observada,latencia_ms,correlacionado,pod,namespace'];
for (const start of starts) {
  const alert = alerts.get(start.marker);
  const latency = alert ? Number(toNanoseconds(alert.time) - toNanoseconds(start.started)) / 1e6 : '';
  rows.push([start.scenario, start.iteration, start.marker, start.started, alert?.time || '', alert?.rule || '', latency === '' ? '' : latency.toFixed(3), alert ? 'sim' : 'nao', pod, namespace].join(','));
}
fs.writeFileSync(outputPath, `${rows.join('\n')}\n`);
NODE

echo "Falco triggers: $STARTS_FILE"
echo "Falco alerts: $RAW_LOG_FILE"
echo "Falco CSV: $CSV_FILE"
echo "Falcosidekick logs: $SIDEKICK_LOG_FILE"

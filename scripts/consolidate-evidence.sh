#!/usr/bin/env bash
set -euo pipefail

WAF_CSV="$1"
FALCO_CSV="$2"
OUTPUT_FILE="$3"

node - "$WAF_CSV" "$FALCO_CSV" "$OUTPUT_FILE" <<'NODE'
const fs = require('fs');
const [wafPath, falcoPath, outputPath] = process.argv.slice(2);
const parse = (path) => {
  const [header, ...lines] = fs.readFileSync(path, 'utf8').trim().split('\n');
  const keys = header.split(',');
  return lines.filter(Boolean).map((line) => Object.fromEntries(keys.map((key, index) => [key, line.split(',')[index] ?? ''])));
};
const median = (values) => {
  const sorted = values.map(Number).sort((a, b) => a - b);
  const mid = sorted.length / 2;
  return sorted.length % 2 ? sorted[Math.floor(mid)] : (sorted[mid - 1] + sorted[mid]) / 2;
};
const waf = parse(wafPath);
const falco = parse(falcoPath);
const wafRows = ['| Cenario | N | HTTP 200 | HTTP 403 | Mediana |', '|---|---:|---:|---:|---:|'];
for (const scenario of [...new Set(waf.map((row) => row.cenario))]) {
  const rows = waf.filter((row) => row.cenario === scenario);
  wafRows.push(`| ${scenario} | ${rows.length} | ${rows.filter((row) => row.http_code === '200').length} | ${rows.filter((row) => row.http_code === '403').length} | ${(median(rows.map((row) => row.time_total_s)) * 1000).toFixed(3)} ms |`);
}
const falcoRows = ['| Cenario | N | Correlacionados | Cobertura | Mediana |', '|---|---:|---:|---:|---:|'];
for (const scenario of [...new Set(falco.map((row) => row.cenario))]) {
  const rows = falco.filter((row) => row.cenario === scenario);
  const correlated = rows.filter((row) => row.correlacionado === 'sim');
  falcoRows.push(`| ${scenario} | ${rows.length} | ${correlated.length} | ${((correlated.length / rows.length) * 100).toFixed(1)}% | ${median(correlated.map((row) => row.latencia_ms)).toFixed(3)} ms |`);
}
const report = [
  '# Resumo consolidado da execucao',
  '',
  '## WAF',
  '',
  ...wafRows,
  '',
  '## Falco',
  '',
  ...falcoRows,
  '',
  'Os valores representam a execucao indicada pelos arquivos CSV informados ao consolidado.'
].join('\n');
fs.writeFileSync(outputPath, `${report}\n`);
NODE

echo "Consolidated report: $OUTPUT_FILE"

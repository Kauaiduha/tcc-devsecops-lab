#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const [runDirectory, outputFile = path.join(runDirectory || '', 'dashboard-data.json')] = process.argv.slice(2);

if (!runDirectory) {
  console.error('Usage: generate-dashboard-data.mjs <run-directory> [output-json]');
  process.exit(2);
}

function readFileIfPresent(file) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') return '';
    throw error;
  }
}

function readJsonIfPresent(file, fallback) {
  const content = readFileIfPresent(file);
  if (!content) return fallback;
  try {
    return JSON.parse(content);
  } catch {
    return fallback;
  }
}

function parseCsv(file) {
  const content = readFileIfPresent(file).trim();
  if (!content) return [];
  const [header, ...lines] = content.split(/\r?\n/);
  const keys = header.split(',');
  return lines.filter(Boolean).map((line) => {
    const values = line.split(',');
    return Object.fromEntries(keys.map((key, index) => [key, values[index] ?? '']));
  });
}

function median(values) {
  const sorted = values.filter(Number.isFinite).sort((a, b) => a - b);
  if (!sorted.length) return null;
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}

function wafScenario(rows, key, expectedCondition, label, action) {
  const entries = rows.filter((row) => row.cenario === key);
  const expected = entries.filter(expectedCondition).length;
  return {
    key,
    label,
    action,
    attempts: entries.length,
    expected,
    successRate: entries.length ? (expected / entries.length) * 100 : null,
    medianMs: median(entries.map((row) => Number(row.time_total_s) * 1000)),
    observedCodes: [...new Set(entries.map((row) => row.http_code).filter(Boolean))],
  };
}

function falcoScenario(rows, key, label, expectedRule) {
  const entries = rows.filter((row) => row.cenario === key);
  const detected = entries.filter((row) => row.correlacionado === 'sim' && row.regra_observada === expectedRule).length;
  return {
    key,
    label,
    expectedRule,
    attempts: entries.length,
    detected,
    coverage: entries.length ? (detected / entries.length) * 100 : null,
    medianMs: median(entries.filter((row) => row.correlacionado === 'sim').map((row) => Number(row.latencia_ms))),
  };
}

const wafRows = parseCsv(path.join(runDirectory, 'waf', 'waf-resultados.csv'));
const falcoRows = parseCsv(path.join(runDirectory, 'falco', 'falco-resultados.csv'));
const labProfile = readJsonIfPresent(path.join(runDirectory, 'lab-profile.json'), {
  mode: 'defendido',
  description: 'Perfil defendido assumido porque nao ha registro de perfil nesta coleta.',
  changedAt: null,
});
const wafLogs = readFileIfPresent(path.join(runDirectory, 'waf', 'waf-modsecurity.log'))
  .split(/\r?\n/).filter(Boolean).slice(-8);
const rawEvents = readFileIfPresent(path.join(runDirectory, 'falco', 'falco-alertas.jsonl'))
  .split(/\r?\n/).flatMap((line) => {
    try {
      const event = JSON.parse(line);
      if (!event.rule || !event.output_fields?.['k8s.pod.name']) return [];
      return [{
        time: event.time,
        rule: event.rule,
        priority: event.priority,
        pod: event.output_fields['k8s.pod.name'],
        namespace: event.output_fields['k8s.ns.name'],
        command: event.output_fields['proc.cmdline'] || '',
        file: event.output_fields['fd.name'] || '',
      }];
    } catch {
      return [];
    }
  }).slice(-10).reverse();
const sidekickLogs = readFileIfPresent(path.join(runDirectory, 'falco', 'falcosidekick.log'))
  .split(/\r?\n/).filter(Boolean);

const wafEnforcing = labProfile.mode !== 'baseline';
const wafScenarios = [
  wafScenario(wafRows, 'sqli', (row) => wafEnforcing ? Number(row.http_code) === 403 : Number(row.http_code) !== 403, 'SQL Injection', wafEnforcing ? 'blocked' : 'forwarded'),
  wafScenario(wafRows, 'xss', (row) => wafEnforcing ? Number(row.http_code) === 403 : Number(row.http_code) !== 403, 'XSS', wafEnforcing ? 'blocked' : 'forwarded'),
  wafScenario(wafRows, 'benign_root', (row) => Number(row.http_code) === 200, 'Trafego benigno: raiz', 'allowed'),
  wafScenario(wafRows, 'benign_search', (row) => Number(row.http_code) === 200, 'Trafego benigno: busca', 'allowed'),
];
const attackSignature = {
  sqli: 'test%27+or+1%3d1--',
  xss: 'q=%3cscript%3ealert',
};
const impactScenarios = wafScenarios.filter((scenario) => scenario.key in attackSignature).map((scenario) => {
  const entries = wafRows.filter((row) => row.cenario === scenario.key);
  const matchingAccessLog = wafLogs.find((line) => line.toLowerCase().includes(attackSignature[scenario.key]));
  // Ingress access logs use "-" after the upstream list when ModSecurity denies before proxying.
  const reachedBackend = Boolean(matchingAccessLog && /\[devsecops-lab-juice-shop-3000\] \[\] (?!-)/.test(matchingAccessLog));
  return {
    key: scenario.key,
    label: scenario.label,
    attempts: entries.length,
    reachedBackend,
    blockedByWaf: entries.filter((row) => Number(row.http_code) === 403).length,
    observedCodes: scenario.observedCodes,
    medianResponseBytes: median(entries.map((row) => Number(row.response_bytes))),
  };
});
const falcoScenarios = [
  falcoScenario(falcoRows, 'C5', 'Execucao de processo', 'Exec into Juice Shop'),
  falcoScenario(falcoRows, 'C6', 'Leitura de /etc/passwd', 'Read sensitive file in Juice Shop'),
];

const payload = {
  generatedAt: new Date().toISOString(),
  runDirectory,
  pipeline: {
    state: 'historical',
    label: 'Evidencia historica',
    title: 'Gate de supply chain bloqueado pelo Trivy',
    detail: 'No workflow validado, build e SAST foram concluídos; o SCA bloqueou o artefato do Juice Shop por achados HIGH e CRITICAL. Este painel nao reexecuta o GitHub Actions.',
    source: '.github/workflows/devsecops.yml',
  },
  waf: {
    available: wafRows.length > 0,
    mode: labProfile.mode,
    description: labProfile.description,
    scenarios: wafScenarios,
    blocked: wafScenarios.filter((scenario) => scenario.action === 'blocked').reduce((sum, scenario) => sum + scenario.expected, 0),
    forwardedAttacks: wafScenarios.filter((scenario) => scenario.action === 'forwarded').reduce((sum, scenario) => sum + scenario.expected, 0),
    benignAccepted: wafScenarios.filter((scenario) => scenario.action === 'allowed').reduce((sum, scenario) => sum + scenario.expected, 0),
    impact: impactScenarios,
    logs: wafLogs,
  },
  falco: {
    available: falcoRows.length > 0,
    scenarios: falcoScenarios,
    events: rawEvents,
    sidekick: {
      delivered: sidekickLogs.filter((line) => /POST OK \(200\)/i.test(line)).length,
      errors: sidekickLogs.filter((line) => /error|rate limit|fail/i.test(line)).length,
      latest: sidekickLogs.slice(-5),
    },
  },
};

fs.mkdirSync(path.dirname(outputFile), { recursive: true });
fs.writeFileSync(outputFile, `${JSON.stringify(payload, null, 2)}\n`);
console.log(`Dashboard data written to ${outputFile}`);

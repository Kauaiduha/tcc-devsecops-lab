#!/usr/bin/env node
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const rootDirectory = path.resolve(scriptDirectory, '..');
const dashboardFile = path.join(rootDirectory, 'docs', 'demo-dashboard.html');
const latestDataFile = path.join(rootDirectory, 'docs', 'demo-output', 'latest', 'dashboard-data.json');
const port = Number(process.env.DASHBOARD_PORT || 4173);
const kubectlContext = process.env.KUBECTL_CONTEXT || 'minikube';

function send(response, status, body, contentType = 'application/json; charset=utf-8') {
  response.writeHead(status, {
    'Content-Type': contentType,
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  response.end(body);
}

function defaultData() {
  return {
    generatedAt: null,
    runDirectory: null,
    pipeline: {
      state: 'historical',
      label: 'Evidencia historica',
      title: 'Gate de supply chain bloqueado pelo Trivy',
      detail: 'Execute um cenario para carregar evidencias ao vivo. O pipeline e apresentado como evidência histórica.',
      source: '.github/workflows/devsecops.yml',
    },
    waf: { available: false, mode: 'defendido', scenarios: [], blocked: 0, forwardedAttacks: 0, benignAccepted: 0, logs: [] },
    falco: { available: false, scenarios: [], events: [], sidekick: { delivered: 0, errors: 0, latest: [] } },
  };
}

function getData() {
  try {
    return JSON.parse(fs.readFileSync(latestDataFile, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return defaultData();
    throw error;
  }
}

function readRequestBody(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    request.on('data', (chunk) => {
      body += chunk;
      if (body.length > 4096) request.destroy();
    });
    request.on('end', () => resolve(body));
    request.on('error', reject);
  });
}

function runProcess(command, argumentsList, environment = process.env) {
  return new Promise((resolve) => {
    const output = [];
    const child = spawn(command, argumentsList, { cwd: rootDirectory, env: environment });
    child.stdout.on('data', (chunk) => output.push(chunk.toString()));
    child.stderr.on('data', (chunk) => output.push(chunk.toString()));
    child.on('error', (error) => resolve({ ok: false, code: 1, output: `${output.join('')}\n${error.message}` }));
    child.on('close', (code) => resolve({ ok: code === 0, code, output: output.join('') }));
  });
}

function podState(pod) {
  if (!pod) return { state: 'Ausente', ready: '0/0', restarts: 0 };
  const statuses = pod.status?.containerStatuses || [];
  const ready = statuses.filter((status) => status.ready).length;
  return {
    name: pod.metadata.name,
    state: pod.status?.phase || 'Desconhecido',
    ready: `${ready}/${statuses.length}`,
    restarts: statuses.reduce((total, status) => total + (status.restartCount || 0), 0),
  };
}

async function getClusterStatus() {
  const environment = { ...process.env, KUBECTL_CONTEXT: kubectlContext };
  const [podsResult, ingressResult] = await Promise.all([
    runProcess('kubectl', ['--context', kubectlContext, 'get', 'pods', '-n', 'devsecops-lab', '-o', 'json'], environment),
    runProcess('kubectl', ['--context', kubectlContext, 'get', 'ingress', 'juice-shop', '-n', 'devsecops-lab', '-o', 'json'], environment),
  ]);
  if (!podsResult.ok || !ingressResult.ok) {
    return { available: false, error: (podsResult.output || ingressResult.output).trim() };
  }
  const pods = JSON.parse(podsResult.output).items || [];
  const ingress = JSON.parse(ingressResult.output);
  const annotations = ingress.metadata?.annotations || {};
  const modSecurity = annotations['nginx.ingress.kubernetes.io/enable-modsecurity'] === 'true';
  const juicePod = pods.find((pod) => pod.metadata.labels?.app === 'juice-shop');
  const ingressPod = pods.find((pod) => pod.metadata.name.startsWith('ingress-nginx-controller-'));
  const falcoPod = pods.find((pod) => /^falco-[a-z0-9]+$/.test(pod.metadata.name));
  return {
    available: true,
    profile: modSecurity ? 'defendido' : 'baseline',
    juiceShop: podState(juicePod),
    ingress: podState(ingressPod),
    falco: podState(falcoPod),
    checkedAt: new Date().toISOString(),
  };
}

function runScenario(scenario, repetitions) {
  return new Promise((resolve) => {
    const output = [];
    const runner = path.join(scriptDirectory, 'run-evaluation.sh');
    const environment = { ...process.env, KUBECTL_CONTEXT: process.env.KUBECTL_CONTEXT || 'minikube' };
    const child = spawn('bash', [runner, scenario, String(repetitions), 'docs/demo-output/latest'], {
      cwd: rootDirectory,
      env: environment,
    });
    const append = (chunk) => {
      output.push(chunk.toString());
      if (output.join('').length > 28000) output.splice(0, 1);
    };
    child.stdout.on('data', append);
    child.stderr.on('data', append);
    child.on('error', (error) => resolve({ ok: false, code: 1, output: `${output.join('')}\n${error.message}` }));
    child.on('close', (code) => resolve({ ok: code === 0, code, output: output.join('') }));
  });
}

function applyProfile(profile) {
  const environment = { ...process.env, KUBECTL_CONTEXT: kubectlContext };
  return runProcess('bash', [path.join(scriptDirectory, 'set-lab-profile.sh'), profile], environment);
}

const server = http.createServer(async (request, response) => {
  const requestUrl = new URL(request.url, `http://${request.headers.host || '127.0.0.1'}`);
  if (request.method === 'GET' && requestUrl.pathname === '/') {
    return send(response, 200, fs.readFileSync(dashboardFile), 'text/html; charset=utf-8');
  }
  if (request.method === 'GET' && requestUrl.pathname === '/api/data') {
    return send(response, 200, JSON.stringify(getData()));
  }
  if (request.method === 'GET' && requestUrl.pathname === '/api/status') {
    return send(response, 200, JSON.stringify(await getClusterStatus()));
  }
  if (request.method === 'POST' && requestUrl.pathname === '/api/run') {
    try {
      const body = JSON.parse(await readRequestBody(request) || '{}');
      const scenario = body.scenario;
      const repetitions = Number(body.repetitions || 1);
      if (!['waf', 'falco', 'all'].includes(scenario) || !Number.isInteger(repetitions) || repetitions < 1 || repetitions > 10) {
        return send(response, 400, JSON.stringify({ ok: false, error: 'Cenario invalido. Use waf, falco ou all, com 1 a 10 repeticoes.' }));
      }
      const result = await runScenario(scenario, repetitions);
      return send(response, result.ok ? 200 : 500, JSON.stringify({ ...result, data: getData() }));
    } catch (error) {
      return send(response, 500, JSON.stringify({ ok: false, error: error.message }));
    }
  }
  if (request.method === 'POST' && requestUrl.pathname === '/api/profile') {
    try {
      const body = JSON.parse(await readRequestBody(request) || '{}');
      if (!['baseline', 'defendido'].includes(body.profile)) {
        return send(response, 400, JSON.stringify({ ok: false, error: 'Perfil invalido. Use baseline ou defendido.' }));
      }
      const result = await applyProfile(body.profile);
      return send(response, result.ok ? 200 : 500, JSON.stringify({ ...result, status: await getClusterStatus() }));
    } catch (error) {
      return send(response, 500, JSON.stringify({ ok: false, error: error.message }));
    }
  }
  return send(response, 404, JSON.stringify({ error: 'Not found' }));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Dashboard local: http://127.0.0.1:${port}`);
  console.log('O servidor aceita conexoes apenas em 127.0.0.1. Use Ctrl+C para encerrar.');
});

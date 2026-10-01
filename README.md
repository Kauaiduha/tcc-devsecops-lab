# TCC DevSecOps Lab

Prova de conceito de DevSecOps em Kubernetes local usando a aplicacao
intencionalmente vulneravel OWASP Juice Shop. O laboratorio combina controles
Shift Left no pipeline e controles Shield Right na borda HTTP e em runtime.

## Componentes

- **Minikube:** cluster Kubernetes local.
- **Juice Shop:** aplicacao-alvo (`bkimminich/juice-shop:latest`).
- **NGINX Ingress + ModSecurity + OWASP CRS:** bloqueio de requisicoes HTTP
  maliciosas antes de chegarem a aplicacao.
- **Falco + Falcosidekick UI:** deteccao e visualizacao de comportamentos em
  runtime.
- **GitHub Actions + SonarCloud + Trivy:** gates de qualidade e seguranca no
  fluxo de CI.

## Pre-requisitos

- Docker em execucao.
- Minikube, `kubectl`, Helm, `curl`, `jq` e Node.js instalados.
- Acesso a Internet na primeira instalacao para baixar imagens e charts.

## Subida do ambiente do zero

Os comandos abaixo foram validados em 23/08/2026 em um Minikube de um no.

```bash
minikube start

kubectl create namespace devsecops-lab

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n devsecops-lab \
  -f waf/ingress-nginx-modsecurity-values.yaml

kubectl apply -f k8s/juice-shop
kubectl wait --for=condition=available deployment/juice-shop \
  -n devsecops-lab --timeout=180s

helm upgrade --install falco falcosecurity/falco \
  -n devsecops-lab \
  -f falco/falco-values.yaml

kubectl get pods -n devsecops-lab -w
```

Espere o pod `falco-*` ficar `2/2 Running`; o primeiro boot pode demorar porque
baixa a imagem do driver do Falco. Interrompa o modo de observacao com `Ctrl+C`.

## Acesso e validacao

O Ingress e exposto como `NodePort`, portanto nao exige `minikube tunnel`.
Descubra o endereco atual dinamicamente:

```bash
export POC_NODE_IP="$(minikube ip)"
export POC_NODE_PORT="$(kubectl get svc ingress-nginx-controller -n devsecops-lab -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')"
export POC_BASE_URL="http://${POC_NODE_IP}:${POC_NODE_PORT}"
export POC_HOST="juice-shop.local"

echo "$POC_BASE_URL"
curl -i -H "Host: $POC_HOST" "$POC_BASE_URL/"
```

Para abrir o Juice Shop no navegador, use o endereco mostrado pelo ultimo
comando com o header `Host` resolvido localmente, ou execute:

```bash
kubectl port-forward -n devsecops-lab svc/juice-shop 3000:3000
```

Em seguida, abra `http://127.0.0.1:3000`.

### WAF

```bash
./scripts/test-waf.sh "$POC_BASE_URL" "$POC_HOST"

kubectl logs deployment/ingress-nginx-controller -n devsecops-lab --tail=200 \
  | grep -E "ModSecurity|403|juice-shop.local|/search|/rest/products/search"
```

Resultado esperado: SQL Injection e XSS retornam `HTTP/1.1 403 Forbidden`, com
registro do ModSecurity/OWASP CRS no log do controller.

### Falco

```bash
./scripts/test-falco.sh devsecops-lab "" /nodejs/bin/node 5 1m
```

Resultado esperado: alertas `Exec into Juice Shop` e `Read sensitive file in
Juice Shop`, incluindo o pod, namespace, comando executado e `/etc/passwd`.

Para visualizar os eventos na interface:

```bash
kubectl port-forward -n devsecops-lab svc/falco-falcosidekick-ui 2802:2802
```

Abra `http://127.0.0.1:2802`. Credenciais do laboratorio: `admin` / `admin`.

## Coleta automatizada

Os helpers de demonstracao permanecem disponiveis, mas o runner abaixo gera
CSVs, logs filtrados e um resumo Markdown para uma execucao completa:

```bash
KUBECTL_CONTEXT=minikube ./scripts/run-evaluation.sh all 10
```

Para rodar somente uma camada:

```bash
KUBECTL_CONTEXT=minikube ./scripts/run-evaluation.sh waf 10
KUBECTL_CONTEXT=minikube ./scripts/run-evaluation.sh falco 10
```

As saidas ficam em `docs/demo-output/`. Revise e promova apenas resultados
validados para `docs/evidencias/`, que e a fonte dos dados do artigo.

## Painel local de demonstracao

O painel local reúne a evidencia historica do pipeline e as coletas ao vivo do
WAF e Falco em uma unica tela. Ele e vinculado apenas a `127.0.0.1` e os botoes
aceitam somente os cenarios controlados `waf`, `falco` e `all`, com uma a dez
repeticoes.

```bash
KUBECTL_CONTEXT=minikube ./scripts/start-dashboard.sh
```

Abra `http://127.0.0.1:4173`. Para uma demonstracao oral, selecione **Fluxo
completo**, mantenha uma repeticao e use **Executar cenario**. O painel chama
`scripts/run-evaluation.sh`, grava a coleta temporaria em
`docs/demo-output/latest/` e atualiza os resultados sem precisar alternar entre
terminais. Interrompa o servidor com `Ctrl+C`.

O card do pipeline e propositalmente marcado como **evidencia historica**: a
interface nao simula nem reexecuta o GitHub Actions. WAF e Falco sao coletados
do cluster em execucao; Falco representa deteccao, e nao bloqueio automatico.

### Comparacao baseline versus defendido

O painel oferece dois perfis versionados para o Ingress do Juice Shop:

- **Baseline:** desativa o enforcement do ModSecurity apenas no Ingress da
  aplicacao. O controller continua instalado e o experimento evidencia que a
  requisicao chegou ao backend.
- **Defendido:** reaplica `k8s/juice-shop/ingress.yaml`, restaurando
  ModSecurity e OWASP CRS com bloqueio HTTP `403`.

Para a demonstracao, aplique **Baseline**, execute `WAF` com uma repeticao,
aplique **Defendido** e repita o mesmo cenario. O painel apresenta o veredito e
os logs do Ingress. No baseline, uma carga pode retornar `200`, `500` ou outro
codigo da aplicacao; o criterio e a ausencia de `403` do WAF e a presenca do
upstream `devsecops-lab-juice-shop-3000` no log, demonstrando encaminhamento ao
Juice Shop. Ao terminar, mantenha o perfil **Defendido**.

O Falco permanece ativo em ambos os perfis. Isso e intencional: ele detecta
comportamento em runtime e nao deve ser apresentado como mecanismo de bloqueio.
O painel mostra os alertas correlacionados, o pod, o comando e a latencia.

## CI/CD

O workflow esta em [`.github/workflows/devsecops.yml`](.github/workflows/devsecops.yml).
Ele executa build, SAST com SonarCloud e SCA de filesystem e imagem com Trivy.
O Trivy bloqueia achados `HIGH` e `CRITICAL`; por isso a imagem vulneravel do
Juice Shop faz o job `sca` falhar intencionalmente, impedindo as etapas
posteriores de push e deploy.

As configuracoes e evidencias de cada camada estao em `waf/`, `falco/`,
`scripts/` e `docs/`.

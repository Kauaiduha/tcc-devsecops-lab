# Saidas Automatizadas da Demo

Este diretorio recebe resultados efemeros gerados pelos scripts de coleta. Cada
execucao cria uma pasta com CSVs, logs filtrados e `resumo.md`.

```bash
KUBECTL_CONTEXT=minikube ./scripts/run-evaluation.sh all 10
```

Para uma demonstracao visual local, inicie o painel na raiz do repositorio:

```bash
KUBECTL_CONTEXT=minikube ./scripts/start-dashboard.sh
```

Ele le e sobrescreve `latest/dashboard-data.json` a cada execucao feita pela
interface. Abra `http://127.0.0.1:4173` no mesmo computador.

O painel tambem controla dois perfis de experimento do WAF: `baseline` e
`defendido`. A alteracao e limitada ao Ingress `juice-shop`; o perfil defendido
reaplica o manifesto versionado. Para executar fora da interface:

```bash
KUBECTL_CONTEXT=minikube ./scripts/set-lab-profile.sh baseline
KUBECTL_CONTEXT=minikube ./scripts/set-lab-profile.sh defendido
```

Deixe o ambiente no perfil `defendido` ao concluir a demonstracao.

Opcoes disponiveis:

```bash
./scripts/run-evaluation.sh waf 10
./scripts/run-evaluation.sh falco 10
./scripts/run-evaluation.sh all 10 docs/demo-output/minha-execucao
```

O modo `waf` executa quatro cenarios por repeticao: SQLi, XSS, raiz benigna e
busca benigna. O modo `falco` executa uma execucao Node.js e uma leitura de
`/etc/passwd` por repeticao. O modo `all` executa ambos e gera um resumo
consolidado.

Revise os dados antes de usa-los no artigo. Resultados aceitos como evidencia
academica devem ser copiados para `docs/evidencias/` com data e descricao do
experimento.

# Entrega 4 - Runtime Security com Falco

## Objetivo

Detectar comportamento anomalo dentro dos containers em execucao, mesmo apos o deploy.

## Estrategia adotada

Foi escolhido Falco com Falcosidekick como solucao de runtime security para o laboratorio.

Durante a validacao inicial, o pod principal do Falco entrou em `CrashLoopBackOff` com a mensagem `could not initialize inotify handler`. A configuracao foi ajustada para:

- usar `falco.rules_files` em vez de `rulesFiles`
- desabilitar `watch_config_files`

Essa decisao evita dependencia de hot reload por inotify neste ambiente e privilegia estabilidade da PoC.

## Ativos preparados no repositorio

- Regras customizadas: [../falco/custom-rules.yaml](/l/disk0/kauaidb/TCC%20POC/falco/custom-rules.yaml:1)
- Values de instalacao: [../falco/falco-values.yaml](/l/disk0/kauaidb/TCC%20POC/falco/falco-values.yaml:1)
- Guia operacional: [../falco/README.md](/l/disk0/kauaidb/TCC%20POC/falco/README.md:1)
- Script de validacao: [../scripts/test-falco.sh](/l/disk0/kauaidb/TCC%20POC/scripts/test-falco.sh:1)

## Alertas customizados previstos

### 1. Exec into Juice Shop

Detecta execucao de processo disparado via `kubectl exec` no container do Juice Shop.

### 2. Read sensitive file in Juice Shop

Detecta leitura de arquivos sensiveis como `/etc/passwd` e do banco SQLite local do Juice Shop dentro do container.

## Fluxo de validacao esperado

1. instalar o Falco no namespace `devsecops-lab`
2. verificar se os pods estao saudaveis
3. executar `scripts/test-falco.sh`
4. verificar no proprio output do script os alertas recentes do Falco e os logs do Falcosidekick
5. se necessario, complementar com consulta manual no log do Falco ou na interface do Falcosidekick

## Resultado esperado

- alerta para exec no container
- alerta para leitura de arquivo sensivel
- confirmacao textual no proprio helper de validacao, sem depender de uma segunda consulta manual obrigatoria

## Evidencias a coletar

- print dos logs do Falco
- print da interface do Falcosidekick
- terminal com os comandos de disparo

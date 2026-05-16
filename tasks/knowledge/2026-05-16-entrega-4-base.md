# Entrega 4 Base

## Contexto

A quarta entrega exige deteccao de comportamento anomalo em runtime dentro dos containers.

## Decisao tomada

Foi adotado Falco com Falcosidekick como stack principal de runtime security do laboratorio.

## Arquivos criados

- `falco/custom-rules.yaml`
- `falco/falco-values.yaml`
- `falco/README.md`
- `scripts/test-falco.sh`
- `docs/entrega-4-runtime-security.md`

## Escopo dos testes

- execucao via `kubectl exec` dentro do Juice Shop
- leitura de arquivo sensivel como `/etc/shadow`

## Ajuste tecnico inicial

O Falco apresentou `could not initialize inotify handler` no primeiro deploy. A configuracao foi corrigida para usar `falco.rules_files` e `watch_config_files: false`, reduzindo o acoplamento ao hot reload por inotify no ambiente do laboratorio.

O container do Juice Shop tambem nao possui `sh`, entao a validacao foi ajustada para usar `/nodejs/bin/node -e ...`. Alem disso, `/etc/shadow` nao existe nessa imagem; por isso, o teste de leitura sensivel passou a usar `/etc/passwd`, que de fato existe no container.

As regras tambem foram simplificadas para usar `k8s.ns.name` e `k8s.pod.name`, evitando depender de detalhes de imagem ou parent process que variam entre runtimes.

# Validacao de Reinstalacao do Ambiente

## Objetivo

Verificar se a PoC pode ser recriada a partir dos arquivos versionados, sem
depender de configuracao manual previamente existente no namespace Kubernetes.

## Execucao

- Data: 23/08/2026
- Cluster: Minikube, um no (`v1.34.0`, `docker://28.4.0`)
- Namespace inicialmente ausente: `devsecops-lab`
- Minikube: `v1.37.0`
- kubectl cliente: `v1.35.2`
- Helm: `v3.20.0`
- Ingress NGINX: chart `4.15.1`, controller `1.15.1`
- Falco: chart `9.1.0`, Falco `0.44.1`

## Procedimento aplicado

1. Criacao do namespace `devsecops-lab`.
2. Instalacao do `ingress-nginx` com
   `waf/ingress-nginx-modsecurity-values.yaml`.
3. Aplicacao dos manifests em `k8s/juice-shop` e espera pela disponibilidade do
   deployment.
4. Instalacao do Falco e Falcosidekick com `falco/falco-values.yaml`.
5. Espera pela prontidao de todos os pods.
6. Execucao dos helpers `scripts/test-waf.sh` e `scripts/test-falco.sh`.

## Resultado observado

Todos os workloads ficaram prontos:

- `juice-shop`: `1/1 Running`;
- `ingress-nginx-controller`: `1/1 Running`;
- `falco`: `2/2 Running`;
- Falcosidekick, UI e Redis: `Running`.

O teste WAF retornou `HTTP/1.1 403 Forbidden` para payloads de SQL Injection e
XSS. O teste de runtime gerou os alertas customizados `Exec into Juice Shop` e
`Read sensitive file in Juice Shop`, incluindo a leitura de `/etc/passwd`.

## Decisao de reprodutibilidade

O primeiro teste com o servico padrao `LoadBalancer` do ingress ficou aguardando
um IP externo, indisponivel sem `minikube tunnel`. O values file foi ajustado
para `controller.service.type: NodePort`. Assim, o acesso pode ser obtido pelo
IP do no e porta dinamica do servico, sem processo adicional em execucao.

Essa escolha e especifica para o laboratorio local. Em um cluster gerenciado,
um `LoadBalancer` ou controlador exposto por infraestrutura de borda seria a
alternativa usual.

## Observacao operacional

Na primeira instalacao, o Falco pode levar alguns minutos para baixar imagens,
especialmente `falco-driver-loader`. Isso nao e falha se o pod estiver em
`Init` durante o download; aguarde ate o estado `2/2 Running` antes de executar
o script de teste.

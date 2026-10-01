# Protocolo de Avaliacao e Coleta de Evidencias da PoC

## Finalidade

Este protocolo transforma a PoC em uma avaliacao reproduzivel. Ele nao busca provar que as ferramentas sao infaliveis; registra sob quais cenarios elas bloquearam, detectaram ou aceitaram eventos e quais limites permaneceram.

Preencha uma linha da tabela de coleta para cada execucao. Guarde os prints em `docs/evidencias/` com o identificador do teste, por exemplo `C2-01-sqli-403.png`.

## Preparacao unica

```bash
cd "/l/disk0/kauaidb/TCC POC"
kubectl get pods -n devsecops-lab
kubectl get ingress -n devsecops-lab
```

Registre antes dos testes:

- [ ] data e hora;
- [ ] versao/commit do repositorio: `git rev-parse --short HEAD`;
- [ ] IP e porta do Ingress: `kubectl get svc ingress-nginx-controller -n devsecops-lab`;
- [ ] pod atual do Juice Shop;
- [ ] versoes do Falco e do controller quando disponiveis;
- [ ] condicao dos pods: todos `Running` e `Ready`.

## Tabela mestre de coleta

| Execucao | Cenario | Tipo | Resultado esperado | Resultado real | HTTP / alerta | Inicio | Fim | Latencia ms | Print / log |
|---|---|---|---|---|---|---|---|---:|---|
| C1-01 | Gate Trivy | malicioso | pipeline bloqueada | TODO | TODO | TODO | TODO | TODO | TODO |
| C2-01 a C2-10 | SQLi | malicioso | 403 e log CRS | 10/10 bloqueadas | 403 | 23/08/2026 18:57 | 23/08/2026 18:57 | 12,705 mediana | `waf-resultados.csv` |
| C3-01 a C3-10 | XSS | malicioso | 403 e log CRS | 10/10 bloqueadas | 403 | 23/08/2026 18:57 | 23/08/2026 18:57 | 11,679 mediana | `waf-resultados.csv` |
| C4-01 a C4-10 | raiz benigna | benigno | 2xx/3xx | 10/10 aceitas | 200 | 23/08/2026 18:57 | 23/08/2026 18:57 | 8,686 mediana | `waf-resultados.csv` |
| C4-11 a C4-20 | busca benigna | benigno | 2xx/3xx | 10/10 aceitas | 200 | 23/08/2026 18:57 | 23/08/2026 18:57 | 125,453 mediana | `waf-resultados.csv` |
| C5-01 a C5-10 | execucao no pod | malicioso | alerta Falco | 10/10 correlacionados | `Exec into Juice Shop` | 23/08/2026 19:03 | 23/08/2026 19:04 | 196,103 mediana | `falco-resultados.csv` |
| C6-01 a C6-10 | leitura de arquivo | malicioso | alerta Falco | 10/10 correlacionados | `Read sensitive file in Juice Shop` | 23/08/2026 19:03 | 23/08/2026 19:04 | 270,139 mediana | `falco-resultados.csv` |

## C1 - Gate de software supply chain

Objetivo: demonstrar que o pipeline nao permite que uma imagem com achados bloqueantes avance para `push` ou `deploy`.

1. Dispare uma execucao da pipeline por um commit controlado ou `workflow_dispatch`, se configurado.
2. Registre o resultado dos jobs `build`, `sast`, `sca`, `push` e `deploy`.
3. No log do Trivy, registre o tipo do achado, a severidade e o `exit code`.
4. Capture a tela contendo o job `sca` e os jobs posteriores nao executados.

Evidencia minima:

- [ ] print do GitHub Actions;
- [ ] trecho do log do Trivy;
- [ ] identificacao da imagem e do commit analisados.

Interpretacao: a falha do Juice Shop demonstra que o gate e aplicado. Ela nao representa uma taxa geral de deteccao de vulnerabilidades.

## C2 e C3 - SQL Injection e XSS no WAF

### Comparacao de impacto no Juice Shop

Antes dos testes protegidos, execute uma repeticao no perfil `baseline` e outra
no perfil `defendido`. O objetivo nao e explorar ou extrair dados da aplicacao;
e demonstrar, de forma controlada, a diferenca entre uma requisicao encaminhada
ao backend e uma requisicao interrompida na borda.

```bash
KUBECTL_CONTEXT=minikube ./scripts/set-lab-profile.sh baseline
KUBECTL_CONTEXT=minikube ./scripts/run-evaluation.sh waf 1

KUBECTL_CONTEXT=minikube ./scripts/set-lab-profile.sh defendido
KUBECTL_CONTEXT=minikube ./scripts/run-evaluation.sh waf 1
```

No baseline, o criterio de encaminhamento e a presenca de
`[devsecops-lab-juice-shop-3000]` no log do Ingress. A resposta da aplicacao
pode ser `200`, `500` ou outro codigo: o ponto medido e que nao houve `403` do
WAF e que o upstream do Juice Shop foi contatado. No perfil defendido, a
evidencia esperada e `403` sem upstream para a requisicao maliciosa.

Essa comparacao demonstra alcance da aplicacao e efetividade do bloqueio; ela
nao deve ser descrita como prova de exfiltracao de dados ou execucao de XSS sem
um experimento especifico que registre esses efeitos.

Defina o endereco do Ingress antes do teste:

```bash
export POC_BASE_URL="http://192.168.49.2:31191"
export POC_HOST="juice-shop.local"
```

Substitua `POC_BASE_URL` pelo IP e porta atuais do seu ambiente.

Para uma evidencia funcional rapida:

```bash
./scripts/test-waf.sh "$POC_BASE_URL" "$POC_HOST"
kubectl logs deployment/ingress-nginx-controller -n devsecops-lab --tail=200 | grep -E "ModSecurity|403|juice-shop.local|/search|/rest/products/search"
```

Para medir latencia, execute cada chamada 10 vezes e anote `http_code` e `time_total`:

```bash
for i in $(seq 1 10); do
  curl --get -sS -o /dev/null -w "C2,$i,%{http_code},%{time_total}\n" \
    -H "Host: $POC_HOST" \
    --data-urlencode "q=test' OR 1=1--" \
    "$POC_BASE_URL/rest/products/search"
done

for i in $(seq 1 10); do
  curl --get -sS -o /dev/null -w "C3,$i,%{http_code},%{time_total}\n" \
    -H "Host: $POC_HOST" \
    --data-urlencode "q=<script>alert(1)</script>" \
    "$POC_BASE_URL/search"
done
```

Evidencia minima:

- [ ] resposta HTTP de cada teste;
- [ ] log `Access denied with code 403` para cada tipo de ataque;
- [ ] tempos retornados pelo `curl`;
- [ ] print do terminal com pelo menos SQLi e XSS.

## C4 - Requisicoes benignas e falso positivo do WAF

Este cenario e indispensavel. Sem ele, o trabalho comprova bloqueio, mas nao demonstra que o WAF preserva o uso normal da aplicacao.

```bash
for i in $(seq 1 10); do
  curl -sS -o /dev/null -w "C4,$i,%{http_code},%{time_total}\n" \
    -H "Host: $POC_HOST" \
    "$POC_BASE_URL/"
done

for i in $(seq 1 10); do
  curl --get -sS -o /dev/null -w "C4-search,$i,%{http_code},%{time_total}\n" \
    -H "Host: $POC_HOST" \
    --data-urlencode "q=apple juice" \
    "$POC_BASE_URL/rest/products/search"
done
```

Resultado esperado: respostas de sucesso ou redirecionamento normal da aplicacao, sem bloqueio `403`. Se houver `403`, registre-o como potencial falso positivo e capture o log da regra que o gerou.

## C5 e C6 - Deteccao do Falco

Execute o helper uma vez por repeticao. O script produz dois eventos: execucao de Node.js e leitura de `/etc/passwd`.

```bash
./scripts/test-falco.sh devsecops-lab "" /nodejs/bin/node 5 1m
```

Para evidenciar a correlacao no terminal:

```bash
kubectl logs daemonset/falco -n devsecops-lab --since=2m | grep -E "Exec detectado|Leitura de arquivo sensivel|juice-shop|/etc/passwd"
```

Para medir o tempo de deteccao, anote o horario imediatamente antes da execucao do script e compare-o com o campo `time` do alerta JSON. Use o mesmo fuso horario ao registrar a planilha.

Evidencia minima:

- [ ] saida do script com `exec-test` e `passwd-read-test`;
- [ ] alerta `Exec into Juice Shop`;
- [ ] alerta `Read sensitive file in Juice Shop`;
- [ ] pod, namespace e comando presentes no alerta;
- [ ] print da Falcosidekick UI.

## Falcosidekick UI

```bash
kubectl port-forward -n devsecops-lab svc/falco-falcosidekick-ui 2802:2802
```

Abra `http://127.0.0.1:2802`. No laboratorio, as credenciais padrao sao `admin` / `admin`. Rode o script do Falco novamente apos abrir a UI, filtre por `Warning` e capture os eventos das regras customizadas.

## Consolidacao dos resultados

Depois de preencher a tabela, calcule:

| Indicador | Formula | Resultado final |
|---|---|---|
| Taxa de bloqueio SQLi | bloqueios C2 / execucoes C2 x 100 | 100% (10/10) |
| Taxa de bloqueio XSS | bloqueios C3 / execucoes C3 x 100 | 100% (10/10) |
| Aceitacao benigna | sucessos C4 / execucoes C4 x 100 | 100% (20/20) |
| Falso positivo WAF | bloqueios C4 / execucoes C4 x 100 | 0% (0/20) |
| Cobertura Falco - exec | alertas C5 / execucoes C5 x 100 | 100% (10/10) |
| Cobertura Falco - leitura | alertas C6 / execucoes C6 x 100 | 100% (10/10) |
| Latencia mediana WAF | mediana de `time_total` por cenario | SQLi 12,705 ms; XSS 11,679 ms; raiz 8,686 ms; busca 125,453 ms |
| Tempo mediano de alerta | mediana entre evento e alerta Falco | execucao 196,103 ms; leitura 270,139 ms |

Relate tambem qualquer alerta de host que nao pertença ao Juice Shop. Esse numero caracteriza ruido operacional e nao deve ser misturado aos alertas produzidos pelos cenarios C5 e C6.

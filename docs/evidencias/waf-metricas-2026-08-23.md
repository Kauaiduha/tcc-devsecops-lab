# Resultados do WAF - 23/08/2026

## Metodo

Foram realizadas 40 requisicoes sequenciais ao Ingress NGINX do Minikube: 10
SQL Injection, 10 XSS, 10 acessos benignos a raiz e 10 buscas benignas por
`apple juice`. Cada chamada registrou o codigo HTTP e o `time_total` do curl.
Os dados brutos estao em `waf-resultados.csv`; o extrato de correlacao do WAF
esta em `waf-modsecurity-2026-08-23.log`.

## Resultados

| Cenario | N | Resultado observado | Taxa | Latencia mediana |
|---|---:|---|---:|---:|
| SQL Injection | 10 | 10 respostas 403 | 100% bloqueio | 12,705 ms |
| XSS | 10 | 10 respostas 403 | 100% bloqueio | 11,679 ms |
| Raiz benigna | 10 | 10 respostas 200 | 100% aceitacao | 8,686 ms |
| Busca benigna | 10 | 10 respostas 200 | 100% aceitacao | 125,453 ms |

- Taxa de bloqueio SQLi: **10/10 = 100%**.
- Taxa de bloqueio XSS: **10/10 = 100%**.
- Aceitacao de trafego benigno: **20/20 = 100%**.
- Falso positivo observado: **0/20 = 0%**.
- Taxa de bloqueio total para os dois payloads: **20/20 = 100%**.

## Correlacao e limites

Os logs do controller registraram `ModSecurity: Access denied with code 403` e
a regra OWASP CRS `949110`. O payload SQLi atingiu score de anomalia 5 e o XSS
score 20. A busca benigna por `apple juice` foi encaminhada ao backend com
resposta 200.

Os dados demonstram comportamento do conjunto de payloads e do ambiente local
avaliados. Eles nao permitem afirmar cobertura geral contra SQL Injection ou
XSS, nem representam benchmark de desempenho: a amostra e pequena, sequencial,
de no unico e sem comparacao com o WAF desabilitado. A busca benigna apresentou
variacao maior, incluindo uma observacao de 491,633 ms; por isso a mediana, e
nao a media, foi adotada como estatistica descritiva principal.

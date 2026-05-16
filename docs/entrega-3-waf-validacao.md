# Entrega 3 - Validacao Tecnica do WAF

## Objetivo

Comprovar que requisicoes maliciosas sao barradas antes de chegar ao Juice Shop.

## Configuracao aplicada

- `ingress-nginx` com ModSecurity habilitado
- OWASP Core Rule Set habilitado
- politica customizada centralizada no controller
- `Ingress` da aplicacao apenas com ativacao do WAF

Arquivos relevantes:

- [waf/ingress-nginx-modsecurity-values.yaml](/l/disk0/kauaidb/TCC%20POC/waf/ingress-nginx-modsecurity-values.yaml:1)
- [waf/modsecurity-config.conf](/l/disk0/kauaidb/TCC%20POC/waf/modsecurity-config.conf:1)
- [k8s/juice-shop/ingress.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/ingress.yaml:1)
- [docs/entrega-3-waf-decisao-arquitetural.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-3-waf-decisao-arquitetural.md:1)

## Testes executados

### 1. SQL Injection

Requisicao testada:

```text
/rest/products/search?q=test%27%20OR%201%3D1--
```

Resultado:

- `HTTP/1.1 403 Forbidden`

### 2. XSS

Requisicao testada:

```text
/search?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E
```

Resultado:

- `HTTP/1.1 403 Forbidden`

## Evidencia em log

Os logs do `ingress-nginx-controller` registraram bloqueio do ModSecurity, incluindo:

- regra OWASP CRS `949110`
- mensagem `Access denied with code 403`
- host `juice-shop.local`
- URI `/search`

## Evidencias para colar na entrega

### Print 1 - Resposta 403 para SQL Injection
![alt text](image-1.png)
Cole aqui um print do terminal mostrando:

- execucao do script `scripts/test-waf.sh`
- resposta `HTTP/1.1 403 Forbidden` para o payload de SQLi

Legenda sugerida:

"Figura X - Bloqueio de tentativa de SQL Injection pelo WAF com resposta HTTP 403."

### Print 2 - Resposta 403 para XSS

![alt text](image-2.png)
Cole aqui um print do terminal mostrando:

- resposta `HTTP/1.1 403 Forbidden` para o payload de XSS

Legenda sugerida:

"Figura Y - Bloqueio de tentativa de XSS pelo WAF com resposta HTTP 403."

### Print 3 - Logs do ingress-nginx com ModSecurity

![Logs do ModSecurity](image-3.png)

Os logs do `ingress-nginx-controller` confirmam que o ModSecurity interceptou e bloqueou as requisicoes maliciosas ainda na borda do cluster. Em ambos os casos, o mecanismo registrou `Access denied with code 403`, associando o bloqueio a regras do OWASP Core Rule Set, com destaque para a regra `949110`, referente a avaliacao do escore de anomalia de entrada. Os registros tambem mostram o host `juice-shop.local` e os endpoints atacados, permitindo correlacionar diretamente o evento de seguranca com os testes de SQL Injection e XSS executados na validacao da PoC.

Cole aqui um print dos logs contendo:

- `ModSecurity: Access denied with code 403`
- referencia a regra OWASP CRS
- host `juice-shop.local`

Legenda sugerida:

"Figura Z - Registro do bloqueio no controlador ingress-nginx via ModSecurity/OWASP CRS."

## Trecho textual sugerido para o TCC

"Na validacao da camada Shield Right com WAF, foram executadas requisicoes contendo payloads de SQL Injection e XSS contra a aplicacao OWASP Juice Shop. Em ambos os casos, o `ingress-nginx` com ModSecurity habilitado retornou `HTTP 403 Forbidden`, impedindo que as requisicoes alcancassem a aplicacao. Os logs do controlador registraram o bloqueio pelo OWASP Core Rule Set, confirmando a efetividade do WAF na borda do cluster."

## Conclusao

A Entrega 3 pode ser considerada concluida tecnicamente.

O WAF interceptou e bloqueou os payloads de teste antes de encaminha-los para a aplicacao, produzindo as evidencias esperadas de `403` e registro em log.

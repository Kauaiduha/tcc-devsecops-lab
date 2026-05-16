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

## Conclusao

A Entrega 3 pode ser considerada concluida tecnicamente.

O WAF interceptou e bloqueou os payloads de teste antes de encaminha-los para a aplicacao, produzindo as evidencias esperadas de `403` e registro em log.

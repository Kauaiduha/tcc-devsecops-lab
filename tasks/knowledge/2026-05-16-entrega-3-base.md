# Entrega 3 Base

## Contexto

A terceira entrega exige um WAF na frente do Juice Shop.

## Decisao tomada

Foi adotado ModSecurity embutido no `ingress-nginx` como caminho principal por ser a opcao mais simples de operar no cluster atual.

## Arquivos criados

- `waf/ingress-nginx-modsecurity-values.yaml`
- `waf/modsecurity-config.conf`
- `waf/README.md`
- `scripts/test-waf.sh`

## Ajuste na aplicacao

O ingress do Juice Shop agora contem annotations para habilitar ModSecurity, OWASP CRS e uma regra de laboratorio para bloquear payloads basicos de SQLi/XSS com `403`.

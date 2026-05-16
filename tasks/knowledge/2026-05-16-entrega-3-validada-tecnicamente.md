# Entrega 3 Validada Tecnicamente

## Contexto

O WAF com ModSecurity e OWASP CRS foi aplicado no `ingress-nginx` e testado contra o Juice Shop.

## Resultado

- payload de SQLi retornou `403`
- payload de XSS retornou `403`
- logs do controller registraram bloqueio do ModSecurity

## Decisao relevante

A politica do WAF permaneceu centralizada no controller, enquanto o `Ingress` da aplicacao apenas habilitou a protecao.

## Implicacao

A Entrega 3 pode ser tratada como concluida tecnicamente. Restam apenas evidencias visuais e organizacao academica do material.

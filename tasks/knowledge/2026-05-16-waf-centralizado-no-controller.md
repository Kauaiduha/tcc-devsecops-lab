# WAF Centralizado no Controller

## Contexto

O `ingress-nginx` rejeitou a annotation `modsecurity-snippet` no `Ingress` do Juice Shop por considera-la arriscada.

## Decisao

A logica customizada do ModSecurity deve ficar centralizada no controller, enquanto o `Ingress` da aplicacao deve apenas habilitar o uso do WAF.

## Motivo

- menor atrito com politicas do controller
- melhor governanca
- padrao mais comum de operacao
- menor superficie de risco por app

## Impacto

O `Ingress` fica mais simples e o controller concentra a politica de seguranca. Em troca, a leitura da protecao completa exige olhar tanto os values do Helm quanto o YAML do `Ingress`.

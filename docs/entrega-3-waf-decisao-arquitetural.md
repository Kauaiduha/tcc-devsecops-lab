# Entrega 3 - Decisao Arquitetural do WAF

## Contexto

Durante a ativacao do ModSecurity no `ingress-nginx`, o controller aceitou a configuracao global via Helm e `ConfigMap`, mas bloqueou a annotation `nginx.ingress.kubernetes.io/modsecurity-snippet` no recurso `Ingress`.

O erro retornado pelo admission webhook foi, em essencia:

- a annotation de grupo ModSecurity foi considerada arriscada com base na configuracao do ingress

## O que isso significa

Ha dois niveis diferentes de configuracao envolvidos:

1. configuracao global do controller `ingress-nginx`
2. ativacao do WAF no `Ingress` especifico da aplicacao

No nosso caso:

- a configuracao global do ModSecurity e das regras base pode ficar no controller
- o `Ingress` da aplicacao apenas liga esse comportamento para a rota protegida

## Decisao tomada

Para esta PoC, a estrategia adotada sera:

- manter no controller `ingress-nginx` a configuracao global do ModSecurity
- manter no controller a regra customizada de laboratorio
- deixar no `Ingress` do Juice Shop apenas as annotations de ativacao:
  - `nginx.ingress.kubernetes.io/enable-modsecurity: "true"`
  - `nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"`

## Por que tirar o `modsecurity-snippet` do Ingress

### 1. Menor atrito com politicas do controller

Controllers modernos de `ingress-nginx` frequentemente endurecem o uso de snippets por motivos de seguranca operacional. Isso reduz o risco de um time ou aplicacao injetar diretivas potencialmente perigosas diretamente no `Ingress`.

### 2. Separacao mais limpa de responsabilidades

Quando a regra fica no controller:

- a politica de seguranca fica centralizada
- a aplicacao apenas consome a protecao
- fica mais facil governar, revisar e auditar regras

Quando a regra fica no `Ingress`:

- cada aplicacao pode tentar carregar logica propria
- aumenta o acoplamento entre rota de negocio e politica de seguranca
- a manutencao tende a ficar mais dispersa

### 3. Mais proximo do padrao operacional comum

Em ambientes reais, e comum que:

- a equipe de plataforma ou seguranca controle a configuracao base do WAF no controller
- as aplicacoes apenas habilitem o uso do WAF no `Ingress`
- regras customizadas sejam promovidas de forma centralizada, e nao replicadas por app

Isso nao significa que snippets por `Ingress` nunca sejam usados, mas sim que eles costumam ser restritos ou fortemente governados.

### 4. Menor superficie de risco

Snippets em annotations sao poderosos. Justamente por isso sao tratados como risco. Permitir logica de seguranca arbitraria no `Ingress` amplia a superficie de erro humano, bypass acidental ou configuracao insegura.

## Impacto pratico da decisao

### Vantagens

- reduz bloqueios do admission webhook
- deixa a PoC mais aderente a uma governanca centralizada
- simplifica a explicacao arquitetural no TCC
- facilita reaproveitamento da politica para outras aplicacoes

### Trade-offs

- a regra customizada deixa de estar visivel diretamente no YAML do `Ingress`
- parte importante da logica fica no `ConfigMap` do controller e nos values do Helm
- para entender toda a protecao, e preciso olhar controller e `Ingress`

## Como isso deve ser descrito no TCC

Uma forma objetiva de explicar:

"Optou-se por centralizar a politica do WAF no controlador `ingress-nginx`, mantendo no recurso `Ingress` apenas a ativacao do ModSecurity e do conjunto OWASP CRS. Essa decisao reduz o risco operacional associado a annotations sensiveis, melhora a governanca da configuracao e se aproxima de um modelo mais comum de administracao centralizada de seguranca em ambientes Kubernetes."

## Estado final esperado

Depois dessa decisao:

- o controller `ingress-nginx` carrega a configuracao global do ModSecurity
- o `Ingress` do Juice Shop apenas habilita o WAF para a aplicacao
- os testes de SQLi/XSS devem retornar `403` se as regras estiverem ativas

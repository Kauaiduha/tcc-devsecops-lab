# Entrega 3 - Evidencias

Use este arquivo como guia para montar a evidencia final da Entrega 3.

## Checklist

- [ ] Print do teste de SQLi com `403 Forbidden`
- [ ] Print do teste de XSS com `403 Forbidden`
- [ ] Print dos logs do `ingress-nginx-controller` mostrando bloqueio do ModSecurity
- [ ] Opcional: print do navegador ou terminal mostrando a tentativa bloqueada

## Comandos uteis

### Executar os testes

```bash
cd "/l/disk0/kauaidb/TCC POC"
./scripts/test-waf.sh "http://192.168.49.2:31191" "juice-shop.local"
```

### Ver logs

```bash
kubectl logs deployment/ingress-nginx-controller -n devsecops-lab --tail=100
```

## O que deve aparecer

### Terminal de teste

- `HTTP/1.1 403 Forbidden` para SQLi
- `HTTP/1.1 403 Forbidden` para XSS

### Logs

- `ModSecurity: Access denied with code 403`
- identificacao de regra OWASP CRS
- referencia ao host ou URI testado

## Observacao importante

Nesta PoC, a politica do WAF foi centralizada no controller `ingress-nginx`, enquanto o `Ingress` da aplicacao manteve apenas a ativacao do WAF. O racional dessa decisao esta em:

- [docs/entrega-3-waf-decisao-arquitetural.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-3-waf-decisao-arquitetural.md:1)

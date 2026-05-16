# WAF Setup

## Strategy

This repository uses ModSecurity embedded in `ingress-nginx` as the default path for Entrega 3.

## Files

- Helm values for the ingress controller: [ingress-nginx-modsecurity-values.yaml](/l/disk0/kauaidb/TCC%20POC/waf/ingress-nginx-modsecurity-values.yaml:1)
- Lab rule set: [modsecurity-config.conf](/l/disk0/kauaidb/TCC%20POC/waf/modsecurity-config.conf:1)
- Protected application ingress: [../k8s/juice-shop/ingress.yaml](/l/disk0/kauaidb/TCC%20POC/k8s/juice-shop/ingress.yaml:1)
- Architectural decision record: [../docs/entrega-3-waf-decisao-arquitetural.md](/l/disk0/kauaidb/TCC%20POC/docs/entrega-3-waf-decisao-arquitetural.md:1)

## Apply in the cluster

If `ingress-nginx` is already installed, upgrade it:

```bash
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  -n devsecops-lab \
  -f waf/ingress-nginx-modsecurity-values.yaml
```

If it is not installed yet:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n devsecops-lab \
  -f waf/ingress-nginx-modsecurity-values.yaml
```

Then re-apply the ingress:

```bash
kubectl apply -f k8s/juice-shop/ingress.yaml
```

In this repository, custom ModSecurity logic is intentionally centralized in the controller instead of being kept in the `Ingress` snippet annotation. The rationale is documented in the architectural decision record above.

## Validation

Use the helper script:

```bash
scripts/test-waf.sh
```

Expected result:

- the malicious requests return `403`
- ingress-nginx logs show ModSecurity activity

## Suggested evidence

- `curl` output with `403 Forbidden`
- ingress controller logs
- browser attempt or terminal output showing the request blocked before reaching Juice Shop

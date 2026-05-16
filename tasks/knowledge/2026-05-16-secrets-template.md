# Secrets Template

## Contexto

Foi criada uma estrutura padrao para armazenar credenciais locais fora do versionamento.

## Arquivos relevantes

- `.gitignore`
- `secrets/devsecops.env.example`
- `secrets/kubeconfig.example`
- `docs/secrets-setup.md`

## Decisao

Credenciais reais devem ficar em `secrets/devsecops.env` e opcionalmente em `secrets/kubeconfig`, ambos ignorados pelo git.

## Beneficio

Isso permite preparar pipeline, registry e deploy sem expor segredos no repositorio.

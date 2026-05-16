# Entrega 2 Base

## Contexto

A segunda entrega exigia pipeline CI/CD com build, SonarQube, Trivy, push e gate de seguranca.

## Decisao tomada

- Como o repositorio ainda nao contem codigo-fonte proprio da aplicacao, a imagem de build foi modelada como um wrapper minimo sobre `bkimminich/juice-shop:latest`
- O pipeline foi estruturado em `.github/workflows/devsecops.yml`
- O deploy em CI ficou desabilitado ate que credenciais de cluster sejam adicionadas

## Evidencia de design

- `Dockerfile`
- `.github/workflows/devsecops.yml`
- `sonar-project.properties`
- `pipeline/README.md`
- `scripts/run-trivy-local.sh`

## Restricao importante

O valor academico da etapa 2 aumenta bastante quando o repositorio passar a conter codigo ou configuracoes adicionais que o SonarQube possa analisar de forma mais rica.

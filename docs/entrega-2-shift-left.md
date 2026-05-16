# Entrega 2 - Pipeline CI/CD com Shift Left

## Objetivo

Garantir que artefatos inseguros nao avancem no pipeline sem passar por verificacoes de seguranca.

## Implementacao realizada

Os ativos tecnicos da Entrega 2 foram implementados neste repositorio:

- Workflow CI/CD: [/.github/workflows/devsecops.yml](/l/disk0/kauaidb/TCC%20POC/.github/workflows/devsecops.yml:1)
- Build da imagem: [Dockerfile](/l/disk0/kauaidb/TCC%20POC/Dockerfile:1)
- Configuracao do Sonar: [sonar-project.properties](/l/disk0/kauaidb/TCC%20POC/sonar-project.properties:1)
- Apoio local ao Trivy: [scripts/run-trivy-local.sh](/l/disk0/kauaidb/TCC%20POC/scripts/run-trivy-local.sh:1)
- Notas do pipeline: [pipeline/README.md](/l/disk0/kauaidb/TCC%20POC/pipeline/README.md:1)

## Fluxo implementado

O workflow foi estruturado em jobs sequenciais:

1. `build`
2. `sast`
3. `sca`
4. `push`
5. `deploy` desabilitado nesta fase

## Resultado tecnico obtido

O pipeline foi validado com sucesso ate o ponto de verificacao de seguranca:

- `build`: concluido com sucesso
- `sast`: concluido com sucesso via SonarQube Cloud
- `sca`: executado com Trivy e bloqueando a esteira quando encontra achados relevantes

Na validacao atual, o Trivy interrompeu o pipeline durante o `image scan` ao detectar material sensivel embutido na imagem do OWASP Juice Shop.

## Interpretacao do resultado

Esse comportamento e esperado no contexto deste TCC.

O OWASP Juice Shop e uma aplicacao intencionalmente vulneravel, usada aqui como alvo didatico. Portanto, a falha do Trivy nao representa defeito da pipeline; ela representa justamente o funcionamento correto do gate de seguranca.

Em outras palavras:

- o pipeline esta operacional
- os controles estao ativos
- a esteira barrou um artefato inseguro antes de qualquer push ou deploy

## Evidencia observada

Durante a execucao do `Trivy image scan`, foram detectados achados do tipo `AsymmetricPrivateKey (private-key)` em arquivos do Juice Shop, fazendo o job falhar com `exit code 1`.

Esse resultado atende ao objetivo da entrega ao demonstrar a acao de `Shift Left`.

## O que capturar para a entrega formal

- Print do workflow no GitHub Actions com `build` e `sast` aprovados e `sca` bloqueando
- Trecho do log do Trivy mostrando o achado e o `exit code 1`
- Texto explicando que a falha e intencional e valida o gate de seguranca

## Conclusao

A Entrega 2 pode ser considerada concluida tecnicamente.

O que resta para a submissao academica e organizar as evidencias visuais e descrever formalmente que o bloqueio observado e o resultado esperado para uma aplicacao propositalmente insegura como o OWASP Juice Shop.

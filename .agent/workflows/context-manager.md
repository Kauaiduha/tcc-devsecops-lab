# /context-manager

Objetivo: manter a memoria persistente sincronizada ao final de cada tarefa relevante.

## Procedimento

1. Comparar o estado atual do repositorio com `MEMORY.md`.
2. Atualizar `MEMORY.md` quando houver mudanca de stack, arquitetura, status, decisoes ou pendencias.
3. Atualizar `tasks/_INDEX.md` quando surgirem novos fluxos, diretorios ou arquivos centrais.
4. Se houver aprendizado reutilizavel, criar ou atualizar `tasks/knowledge/YYYY-MM-DD-assunto.md`.
5. Se houver desenho tecnico novo, criar um arquivo em `tasks/plans/`.
6. Registrar explicitamente qualquer ausencia importante, como `README.md`, pipeline, WAF ou runtime security, ate que esses artefatos existam.

## Quando usar

- Ao concluir uma entrega
- Ao adicionar novos manifests ou workflows
- Ao criar pipeline, WAF ou Falco
- Ao descobrir uma restricao operacional relevante

## Regras

- Basear a memoria em arquivos reais e evidencias reais.
- Nao apagar historico util de conhecimento; acrescentar e consolidar.
- Preferir notas curtas, concretas e acionaveis.

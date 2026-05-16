# /context-load

Objetivo: recarregar o contexto persistente deste repositorio no inicio de cada sessao.

## Procedimento

1. Ler `MEMORY.md` por completo.
2. Ler `tasks/_INDEX.md` por completo.
3. Listar `tasks/knowledge/` e abrir as entradas mais recentes, priorizando as ultimas 3.
4. Listar `tasks/plans/` e abrir qualquer plano ativo relevante para a tarefa atual.
5. Validar se os caminhos citados em `MEMORY.md` e `tasks/_INDEX.md` ainda existem.
6. Resumir o estado atual do projeto antes de executar qualquer mudanca.

## Regras

- Nao inventar stack, modulos ou historico ausente.
- Se `README.md` continuar ausente, usar a estrutura de pastas e manifests como fonte primaria.
- Se o git continuar indisponivel, registrar isso no resumo de sessao.

# Estudo de SQL: Intuito da Conversa e Projeto Final

## Resumo

Este documento registra **por que** o roteiro de SQL existe, **quais decisões** foram tomadas na conversa que o criou e **o que é o projeto final** (módulos 21 e 22 do `roteiro-sql.md`). Ele serve como ponto de partida para qualquer conversa futura sobre o estudo de SQL: em vez de explicar o contexto de novo, basta pedir para ler este arquivo.

| Seção | O que responde |
|-------|----------------|
| 1. Intuito | Qual é o objetivo do estudo |
| 2. Como chegamos ao roteiro | O caminho da conversa, do "o que é SQL" até o plano |
| 3. Decisões combinadas | As escolhas feitas e o porquê de cada uma |
| 4. Projeto final | O que construir, as regras e como saber que terminou |
| 5. Ligação com o TypeScript | Como o projeto final conversa com o outro roteiro |
| 6. Como seguir | O fluxo de estudo combinado |

---

## 1. Intuito

**Objetivo:** aprender SQL com PostgreSQL partindo do zero absoluto, até o nível que é cobrado em **trabalho real e entrevistas**, sem entrar em temas muito específicos ou de nível sênior.

**Princípios do estudo** (os mesmos do projeto "Dev Studies"):
1. **Fundamento antes do atalho**: cada conceito é explicado de forma atômica, do mais simples ao mais composto.
2. **Prática logo depois da teoria**: conteúdo, depois exercícios graduais, depois um desafio.
3. **Fontes sempre citadas**: cada módulo aponta para a documentação oficial.
4. **Correção por conversa**: não há gabarito. As soluções são enviadas no chat para correção e discussão de alternativas.

---

## 2. Como chegamos ao roteiro

A conversa seguiu um caminho de entendimento em três passos:

**Passo 1: o que é SQL e quais opções existem.**
- SQL é uma **linguagem**, não um banco. Quem executa o SQL é um **SGBD** (Sistema Gerenciador de Banco de Dados).
- Os SGBDs relacionais mais usados hoje são PostgreSQL, MySQL, MariaDB, SQLite, SQL Server e Oracle. O PostgreSQL lidera a preferência dos desenvolvedores na pesquisa do Stack Overflow desde 2023.
- Dá para isolar qualquer SGBD com **Docker**, sem instalar nada no sistema.
- Dá para treinar online sem banco local (sites como SQL Playground, Mode SQL Tutorial, HackerRank e LeetCode).

**Passo 2: alinhamento antes de montar o guia.** Foram feitas perguntas sobre nível atual, ambiente, banco de exemplo, ordem dos conteúdos, gabarito, integração com TypeScript e volume de exercícios. As respostas estão na seção 3.

**Passo 3: construção e teste do roteiro.** O `roteiro-sql.md` foi escrito e **todos os exemplos SQL foram executados** contra o Pagila em um PostgreSQL 18 antes da entrega. O exemplo em TypeScript também foi executado e passou na verificação de tipos.

---

## 3. Decisões combinadas

| Tema | Decisão | Por quê |
|------|---------|---------|
| Ponto de partida | Zero absoluto | Havia uma noção prévia, mas a preferência foi construir a base sem lacunas |
| SGBD | PostgreSQL 18 | Mais adotado em projetos novos, segue de perto o padrão SQL e é gratuito |
| Ambiente | Docker no Omarchy, com `sudo docker` | O Omarchy já traz Docker e, por segurança, não coloca o usuário no grupo `docker` |
| Instalação | `docker-compose.yml` do próprio Pagila | Já carrega os dados e instala a extensão `pgvector`, que o esquema do Pagila exige. O "Docker DB" do menu do Omarchy sobe um banco vazio |
| Banco de exemplo | Pagila (opção B) | Banco oficial da comunidade, realista em volume (cerca de 51 mil aluguéis) |
| Ordem | Consultar primeiro, criar depois | É mais motivador e é o que entrevistas mais cobram |
| Gabarito | Nenhum | As soluções são corrigidas no chat |
| Volume | 4 exercícios e 1 desafio por módulo, mais questões de entrevista por fase | Mesmo padrão do roteiro de TypeScript |
| TypeScript | Só no fim, como módulo extra (22), depois do projeto final | Primeiro dominar o SQL puro; depois conectar ao código |
| Cliente SQL | `psql` como principal, pgAdmin opcional | O `psql` é o que aparece em servidores e em entrevistas práticas |
| Área de trabalho | Schema `estudos` para exercícios; schema `tarefas` para o projeto final | Não misturar o próprio trabalho com o Pagila e poder apagar tudo com segurança |

---

## 4. Projeto final: o banco do Gerenciador de Tarefas

### 4.1 A ideia

Construir **do zero** o banco de dados de um gerenciador de tarefas: modelar, criar as tabelas com regras de integridade, gerar dados, escrever relatórios e medir performance. É o mesmo domínio do projeto final do roteiro de TypeScript, para que o módulo 22 troque o arquivo `tarefas.json` daquela aplicação por este banco.

O projeto vem **depois** dos módulos 0 a 20 porque usa praticamente tudo o que eles ensinam.

### 4.2 Entidades

| Entidade | Conteúdo mínimo |
|----------|-----------------|
| `usuario` | nome, e-mail único, data de criação |
| `projeto` | nome, dono (um usuário) |
| `tarefa` | título, descrição opcional, projeto, responsável opcional, prioridade, status, criada em, prazo opcional, concluída em opcional |
| `etiqueta` | nome único |
| ligação tarefa e etiqueta | relacionamento N:N (uma tarefa tem várias etiquetas e uma etiqueta está em várias tarefas) |
| `comentario` | texto, autor, tarefa, data de criação |

### 4.3 Regras que o banco precisa garantir

1. Toda tabela tem chave primária e todo relacionamento tem chave estrangeira.
2. **Prioridade** só aceita `baixa`, `media` ou `alta`.
3. **Status** só aceita `pendente`, `em_andamento` ou `concluida`.
4. `concluida_em` **só pode estar preenchida quando o status for `concluida`**, e uma tarefa concluída **precisa** ter `concluida_em`. Essa é a regra mais importante do projeto: é a versão em banco de dados da *discriminated union* usada no roteiro de TypeScript.
5. Decidir conscientemente o que acontece com tarefas e comentários quando um usuário ou projeto é apagado (`ON DELETE`), e justificar a escolha em um comentário no SQL.

### 4.4 Entregas

1. **Estrutura** (`01-schema.sql`): começa apagando e recriando o schema `tarefas`, para o projeto poder ser recriado quantas vezes for preciso.
2. **Dados** (`02-dados.sql`): no mínimo 5 usuários, 3 projetos, 40 tarefas, 6 etiquetas e 30 comentários, gerados com `INSERT ... SELECT`, `generate_series` e `random()`.
3. **Oito relatórios** (pasta `consultas/`, um arquivo cada):
   1. Tarefas atrasadas, com responsável e dias de atraso.
   2. Quantidade de tarefas por status em cada projeto.
   3. Usuários sem nenhuma tarefa atribuída.
   4. As 3 etiquetas mais usadas.
   5. Tempo médio de conclusão por prioridade.
   6. Ranking de usuários por tarefas concluídas, com `DENSE_RANK`.
   7. Tarefas concluídas por semana, com total acumulado.
   8. O último comentário de cada tarefa.
4. **Uma view** (`03-views.sql`): o painel de cada projeto (total, concluídas, percentual concluído, atrasadas).
5. **Uma transação** (`05-transacao.sql`): concluir uma tarefa e registrar um comentário automático, tudo ou nada.
6. **Um índice justificado** (`04-indices.sql`): `EXPLAIN ANALYZE` antes e depois, com a explicação da diferença.

### 4.5 Estrutura de pastas

```
~/Projects/learning-postgresql/
  pagila/                 repositório do Pagila (Docker)
  docs/                   roteiro, especificação e cola de comandos
  modulo-01/ ...          exercícios dos módulos
  projeto-final/
    01-schema.sql
    02-dados.sql
    03-views.sql
    04-indices.sql
    05-transacao.sql      tem BEGIN e COMMIT próprios, roda separado
    consultas/
      01-atrasadas.sql
      02-status-por-projeto.sql
      ...
```

### 4.6 Quais módulos cada parte exercita

| Parte | Módulos do roteiro |
|-------|--------------------|
| Tipos, tabelas e constraints | 14, 15 |
| Modelagem e N:N | 16 |
| Geração de dados | 11, 17 |
| Relatórios | 6 a 13 |
| View | 19 |
| Transação | 18 |
| Índice | 20 |

### 4.7 Como saber que terminou

- [ ] Rodar os arquivos `01` a `04` em sequência, do zero, sem nenhum erro.
- [ ] Tentar inserir dados inválidos (prioridade inexistente, tarefa concluída sem data) e ver o banco **recusar**.
- [ ] Os 8 relatórios retornam resultados que fazem sentido com os dados gerados.
- [ ] A transação, se interrompida no meio, não deixa nada pela metade.
- [ ] O índice mostra diferença real no `EXPLAIN ANALYZE`, e a escolha está explicada.
- [ ] Tudo enviado no chat para revisão.

Extras opcionais: histórico de mudanças de status em outra tabela; subtarefas (uma tarefa que aponta para a tarefa-mãe) consultadas com `WITH RECURSIVE`.

---

## 5. Ligação com o roteiro de TypeScript

O projeto final de SQL foi pensado como a **camada de dados** do projeto final de TypeScript (módulo 21 do `roteiro-typescript.md`, o gerenciador de tarefas no terminal).

| No TypeScript | No PostgreSQL |
|---------------|---------------|
| `tarefas.json` lido com `node:fs/promises` | Tabelas do schema `tarefas` |
| `prioridade: "baixa" \| "media" \| "alta"` (union de literais) | Coluna com `CHECK` limitando os três valores |
| `status` como discriminated union (`pendente` ou `concluida` com `concluidaEm`) | Coluna `status` + coluna `concluida_em` + `CHECK` amarrando as duas |
| Validação com erros customizados | Constraints do banco, como segunda linha de defesa |
| Repositório genérico | Funções que fazem consultas parametrizadas |

Uma diferença a decidir na hora da integração: o banco tem o status `em_andamento`, que o projeto de TypeScript não tem. Ou o tipo do TypeScript ganha esse estado, ou ele fica só no banco. Essa é uma boa discussão para o módulo 22.

**Módulo 22 (extra)**: usa a biblioteca `pg` para o TypeScript conversar com o banco. Os conceitos centrais são pool de conexões, **consultas parametrizadas** (proteção contra SQL injection), conversão de `numeric` e `COUNT(*)`, que chegam como texto, e transações no código.

**Ordem recomendada:**
1. Roteiro de TypeScript até o módulo 20 e roteiro de SQL até o módulo 20 (podem andar em paralelo).
2. Projeto final de TypeScript (com `tarefas.json`).
3. Projeto final de SQL (módulo 21).
4. Módulo 22: trocar o JSON pelo PostgreSQL.

---

## 6. Como seguir

1. Fazer o Módulo 0 do `roteiro-sql.md` e mandar no chat o resultado do `\dt` e do exercício 0.1.
2. Para cada módulo: ler os conceitos, digitar os exemplos, prever o resultado antes de rodar, resolver os exercícios em arquivos `.sql`.
3. Mandar as soluções no chat para correção.
4. Ao fim de cada fase, responder as questões de entrevista como se estivesse explicando para alguém.
5. Marcar o progresso no checklist do apêndice C do roteiro.

Em uma conversa nova, basta pedir algo como "leia o `projeto-final-sql.md` e o `roteiro-sql.md`, estou no módulo X" para retomar com todo o contexto.

---

## Fontes

- [Pagila no GitHub](https://github.com/devrimgunduz/pagila): banco de exemplo e `docker-compose.yml`.
- [Omarchy no GitHub](https://github.com/basecamp/omarchy): Docker incluído e decisão de não usar o grupo `docker` por padrão (`install/config/docker.sh`).
- [Documentação oficial do PostgreSQL](https://www.postgresql.org/docs/current/): conceitos usados no projeto (constraints, CTEs, window functions, views, índices).
- [Constraints no PostgreSQL](https://www.postgresql.org/docs/current/ddl-constraints.html): base da seção 4.3.
- [Stack Overflow Developer Survey](https://survey.stackoverflow.co/): preferência por PostgreSQL citada na seção 2.
- [node-postgres](https://node-postgres.com/): módulo 22.
- Documentos do projeto: `roteiro-sql.md` (módulos 21 e 22) e `roteiro-typescript.md` (módulo 21).

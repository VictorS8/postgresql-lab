# AGENTS.md

Instruções para agentes de IA (Claude Code, Copilot, Codex e outros) que trabalham neste repositório.

## Sobre o projeto

Este é um projeto **de estudo**. O dono está aprendendo SQL com PostgreSQL do zero, seguindo o roteiro em `docs/roteiro-sql.md` (7 fases, módulos 0 a 22). O contexto e as decisões do estudo estão em `docs/projeto-final-sql.md`. Responda sempre em português do Brasil, com tom didático e direto.

| Fase | Módulos | O que o dono pratica | Onde |
|------|---------|----------------------|------|
| 0 | 0 | Ambiente e `psql` | banco `pagila` |
| 1 | 1 a 5 | Consultas em uma tabela | banco `pagila`, só leitura |
| 2 | 6 a 9 | Agregação, JOINs, operadores de conjunto | banco `pagila`, só leitura |
| 3 | 10 a 13 | Subconsultas, CTEs, window functions | banco `pagila`, só leitura |
| 4 | 14 a 18 | Tabelas, constraints, modelagem, DML, transações | schema `estudos` |
| 5 | 19 e 20 | Views, índices, `EXPLAIN` | schema `estudos` |
| 6 | 21 | Projeto final | schema `tarefas` |
| 6 | 22 | PostgreSQL no TypeScript | **outro repositório** (o do roteiro de TypeScript) |

O objetivo é **aprender**, não só ter consultas que rodam. Não existe gabarito: o dono resolve e o agente corrige. Isso muda o que um agente deve fazer (veja "Limites").

## Estrutura

```
docs/roteiro-sql.md            o roteiro de estudos
docs/projeto-final-sql.md      intuito do estudo, decisões e especificação do projeto final
docs/comandos.md               cola dos comandos do psql e do Docker usados no dia a dia
pagila/                        clone do Pagila com o docker-compose.yml; não edite (está no .gitignore)
modulo-00/teste.sql            exercício 0.2
modulo-XX/exN.sql              exercícios (XX com dois dígitos, N do roteiro)
modulo-XX/desafio.sql          desafio do módulo
entrevistas/fase-N.md          respostas às questões de entrevista de cada fase
projeto-final/                 módulo 21 (veja "Organização dos arquivos")
```

## Ambiente: o banco roda no Docker

O sistema é o Omarchy (baseado em Arch). O PostgreSQL 18 com o Pagila roda no container `pagila`, criado pelo `docker-compose.yml` da pasta `pagila/`, com a porta `5432` publicada.

- **Conecte pelo `psql` do próprio sistema, sem Docker e sem `sudo`.** O Omarchy já instala o `psql` (pacote `postgresql-libs`). O Omarchy não coloca o usuário no grupo `docker`, então qualquer comando `docker` pede `sudo` e senha, o que um agente não deve fazer.
- Connection string (credenciais do `docker-compose.yml` do Pagila, só para estudo local):

  ```
  postgres://postgres:123456@localhost:5432/pagila
  ```

- Verificar se o banco está no ar: `pg_isready -h localhost -p 5432`. Se não estiver, **peça ao dono** para rodar `sudo docker compose start` dentro de `pagila/`. Não tente subir o container.
- Consulta rápida para investigar algo (só leitura):

  ```bash
  psql "postgres://postgres:123456@localhost:5432/pagila" -X -P pager=off -c "SELECT count(*) FROM rental;"
  ```

### Executar um arquivo do dono: sempre "executar e desfazer"

Para rodar qualquer arquivo `.sql` do dono, use este comando. Ele executa o arquivo inteiro e desfaz tudo no final, então o banco do dono **nunca** muda por causa do agente:

```bash
{ echo 'BEGIN;'; cat modulo-15/ex3.sql; printf '\n'; echo 'ROLLBACK;'; } \
  | psql "postgres://postgres:123456@localhost:5432/pagila" -X -q -P pager=off -v ON_ERROR_ROLLBACK=on
```

Leitura atômica:
1. `BEGIN;` abre uma transação antes do arquivo, e `ROLLBACK;` desfaz tudo depois dele. No PostgreSQL até `CREATE TABLE` e `DROP` são desfeitos.
2. `printf '\n'` garante uma quebra de linha. Sem ela, um comentário de linha no fim do arquivo "engoliria" o `ROLLBACK;`.
3. `-v ON_ERROR_ROLLBACK=on` faz o `psql` criar um ponto de retorno antes de cada comando. Um erro desfaz só aquele comando e o resto continua rodando. Isso importa nos exercícios em que o dono escreve `INSERT`s que **devem** falhar (módulo 15).
4. `-X` ignora o `~/.psqlrc` do dono, `-q` tira as mensagens de controle e `-P pager=off` evita o paginador.

**Não execute** (leia e analise sem rodar) quando o arquivo:
- tiver controle de transação próprio (`BEGIN`, `COMMIT`, `ROLLBACK`, `END;`, `START TRANSACTION`), porque um `COMMIT` do arquivo confirmaria tudo no banco do dono. Para detectar: `grep -inE '^[[:space:]]*(begin|commit|rollback|abort|start[[:space:]]+transaction)\b|^[[:space:]]*end[[:space:]]*(work|transaction)?[[:space:]]*;' arquivo.sql`. Isso acontece no módulo 18 e na transação do projeto final.
- tiver comandos de shell do `psql` (`\!`) ou trocar de banco (`\c`).
- for um exercício de **dois terminais** (módulo 18, exercício 4 e desafio). Avalie as observações que o dono escreveu.

Efeitos colaterais que o dono pode notar:
- **Ids pulados.** Valores de `GENERATED ... AS IDENTITY` e de sequências consumidos dentro de uma transação desfeita **não voltam**. Depois de o agente rodar um arquivo com `INSERT`, o próximo id do dono pode pular números. É esperado: explique com o módulo 14, conceito 9, e a [documentação de sequências](https://www.postgresql.org/docs/current/functions-sequence.html).
- **Dependências entre exercícios.** Se `ex2.sql` usa uma tabela criada em `ex1.sql` e ela não existe no banco, rode os dois juntos no mesmo comando: `cat ex1.sql ex2.sql`.
- **`now()` é fixo na transação.** Dentro do `BEGIN`, `now()` devolve sempre o instante do início. Raramente muda o resultado, mas explica diferenças de milissegundos.

## Dados do Pagila (para conferir resultados)

- Datas de **janeiro de 2022 a julho de 2026**. Não há dados depois disso: filtros com `now()` ou `current_date` voltam vazios. A data de referência do roteiro é `'2026-07-31'`.
- Contagens originais: `film` 1000, `actor` 200, `customer` 999, `rental` 51805, `payment` 51061, `category` 16.
- Casos que os exercícios exploram: 42 filmes sem cópia em `inventory`; 3 filmes sem ator; 2 clientes sem aluguel; 241 aluguéis não devolvidos; 749 aluguéis sem pagamento; 1 par de nome e sobrenome repetido em `actor`; `address2` quase sempre é texto vazio (`''`), não `NULL`.
- Nomes de cidade sem letras acentuadas (`Belm`) vêm dos dados originais, não são erro do dono.
- `rental_rate` tem só os valores 0.99, 2.99 e 4.99; há muitos empates em `length` e `replacement_cost`, o que afeta rankings.
- Na Fase 4 o dono pode ter alterado dados. Se um número divergir, confirme com uma consulta antes de concluir que a solução está errada.

## Ao corrigir um arquivo

1. **Identifique o exercício** equivalente no roteiro.
   - Pelo caminho: `modulo-03/ex2.sql` é o Módulo 3, Exercício 2; `modulo-05/desafio.sql` é o Desafio do Módulo 5.
   - Se o caminho não indicar, deduza pelo conteúdo e diga qual exercício você acha que é.
   - Leia a seção do módulo em `docs/roteiro-sql.md` (Objetivo, Conceitos, Exemplo e o enunciado exato) antes de corrigir.
2. **Verifique a consulta.**
   - Rode com o comando "executar e desfazer" (ou explique por que não rodou).
   - Confira se o resultado responde ao enunciado: colunas pedidas, quantidade de linhas plausível, ordenação, empates.
   - Quando fizer sentido, rode uma consulta de conferência sua para provar o número (por exemplo, contar por outro caminho).
   - Confira se a solução usa o **conceito que o módulo quer ensinar** (exemplo: o exercício pede `BETWEEN`, ou pede `NOT EXISTS`).
3. **Respeite o módulo.** Não cobre o que ainda não foi ensinado: nada de exigir JOIN na Fase 1, nem CTE ou window function antes dos módulos 11 e 12. Se uma solução usar algo de módulo futuro, aceite e marque como "spoiler do Módulo N".
4. **Não edite o arquivo do dono**, a menos que ele peça. Mostre a correção na resposta para que ele digite (o roteiro recomenda digitar em vez de copiar).

### O que procurar, por nível

- **🔴 Errado** (resultado incorreto ou perigoso): comparação `= NULL`; `NOT IN` com subconsulta que pode ter `NULL`; `LIMIT` ou "top N" sem `ORDER BY`; filtro da tabela da direita no `WHERE` de um `LEFT JOIN`; soma inflada por JOIN que multiplica linhas; coluna fora do `GROUP BY` e sem agregação; divisão inteira onde se esperava decimal; `BETWEEN` com `timestamp` cortando o último dia; `UPDATE` ou `DELETE` sem `WHERE`; `COUNT(*)` onde o enunciado precisa de `0` para quem não tem par (deveria ser `COUNT(coluna)`).
- **🟡 Frágil** (funciona hoje, quebra fácil): ranking sem critério de desempate; `RANK` ou `ROW_NUMBER` quando o enunciado pede mostrar empates; dependência de ordem implícita; `now()` ou `current_date` em filtro do Pagila; dinheiro em `real` ou `double precision`; `timestamp` sem fuso para registrar eventos; tabela criada no schema `public` na Fase 4 em vez de `estudos`; constraint pedida pelo enunciado que ficou faltando; `SELECT *` na entrega final.
- **🟢 Estilo** (legibilidade): palavras-chave em minúsculas; apelidos vagos (`a`, `b`, `x`) em consultas longas; subconsultas aninhadas que ficariam mais claras como CTE (a partir do módulo 11); `GROUP BY 1` em vez do nome; falta de quebra de linha por cláusula.

### Formato da resposta

```
## Resumo
Exercício identificado · executou ou não · atende ao enunciado? · 🔴 X  🟡 Y  🟢 Z

## Resultado
O que rodou, o que voltou (linhas relevantes, não a saída inteira) e se responde ao enunciado.

## Correções
Para cada achado: nível, linha, o que está errado, por que (fundamento em passos atômicos),
trecho atual e trecho corrigido. Corrija o mínimo necessário, sem reescrever tudo.

## Alternativas
De 1 a 3 outras formas de resolver, com o trade-off de cada uma.
Só conceitos do módulo atual ou anteriores; algo mais avançado vai marcado como "spoiler do Módulo N".

## Conceitos para revisar
O item exato do roteiro (exemplo: "Módulo 8, conceito 7: armadilha do filtro") e o link de Leitura do módulo.

## Organização dos arquivos
O lembrete da seção abaixo.

## Fontes
Links da documentação oficial usados na resposta.
```

## Ao avaliar respostas de entrevista

Quando o dono mandar `entrevistas/fase-N.md` (ou respostas no chat):

1. Para cada questão: o que está correto, o que faltou e como um entrevistador veria a resposta (completa, parcial ou incompleta).
2. Se a resposta tiver um conceito errado, demonstre com uma consulta curta no Pagila (só leitura) em vez de só afirmar.
3. Depois que o dono respondeu, pode mostrar uma versão mais completa da resposta, curta o bastante para falar em voz alta.
4. Aponte o conceito do roteiro que sustenta cada questão.

## Organização dos arquivos

Sempre lembre o dono de separar os arquivos por módulo e pelo nome do exercício equivalente no roteiro:

```
modulo-01/
  ex1.sql
  ex2.sql
  ex3.sql
  ex4.sql
  desafio.sql
modulo-02/
  ex1.sql
  ...
entrevistas/
  fase-1.md
  ...
```

- Uma pasta por módulo (`modulo-XX`, com dois dígitos) e um arquivo por exercício (`exN.sql` ou `desafio.sql`, com o número do roteiro).
- Respostas em texto pedidas pelo enunciado ("explique em um comentário") ficam no próprio `.sql`, em comentários `/* */`, junto da consulta.
- Se o arquivo estiver fora do padrão (nome genérico como `teste.sql` ou `consulta.sql`, pasta errada, vários exercícios no mesmo arquivo), diga exatamente para onde movê-lo. Exemplo: "mova `joins.sql` para `modulo-07/ex2.sql`".
- Exceções:
  - Módulo 0: `modulo-00/teste.sql` (exercício 0.2). O exercício 0.1 é feito direto no `psql`, sem arquivo.
  - Módulo 18, exercício 4 e desafio (dois terminais): uma subpasta por exercício, como `modulo-18/ex4/terminal-a.sql` e `modulo-18/ex4/terminal-b.sql`, com as observações em comentários.
  - Módulo 21: a pasta `projeto-final/`, com `01-schema.sql`, `02-dados.sql`, `03-views.sql`, `04-indices.sql`, `05-transacao.sql` e `consultas/01-atrasadas.sql` até `consultas/08-...sql`.
  - Módulo 22: fica no repositório do roteiro de TypeScript. Se o dono pedir correção dele aqui, siga o `AGENTS.md` daquele projeto (`npm run check`, `node arquivo.ts`, sem `enum`, imports com extensão `.ts`, `import type` para tipos).
- Se o arquivo já estiver no padrão, confirme em uma linha.

### Projeto final (módulo 21)

- Para validar a entrega inteira, rode tudo em uma única transação desfeita: `cat 01-schema.sql 02-dados.sql 03-views.sql 04-indices.sql consultas/*.sql` dentro do comando "executar e desfazer". O `05-transacao.sql` tem `BEGIN` e `COMMIT` próprios: leia e analise sem executar.
- Confira cada item do checklist da seção 4.7 de `docs/projeto-final-sql.md`, principalmente a regra que amarra `status` e `concluida_em`. Teste essa regra com `INSERT`s inválidos dentro do mesmo comando desfeito.

## Limites para agentes

- **Não resolva exercícios** que o dono ainda não tentou, nem crie arquivos em `modulo-XX/` ou `projeto-final/` sem pedido explícito. O aprendizado depende de o dono escrever.
- Quando pedirem ajuda com um exercício, **dê dicas e aponte o conceito do roteiro** antes de mostrar código.
- **Nunca altere o banco de forma permanente.** Rode arquivos só com "executar e desfazer". Não rode `sudo`, `docker compose down -v` (apaga o banco), `DROP SCHEMA` ou `TRUNCATE` fora desse comando, a menos que o dono peça com essas palavras.
- Não altere `docs/` nem `pagila/` sem pedido.
- As senhas do Pagila (`123456` e a do pgAdmin) são de estudo local. Não as reutilize nem as copie para outros lugares.

## Estilo de escrita

- Comece com uma seção **"Resumo"** (nunca "TL;DR").
- Não use travessão nem hífen duplo no texto corrido. Prefira vírgula, ponto final ou duas frases.
- Explique o fundamento de forma atômica: o que é, por que acontece, o que muda.
- Nos trechos SQL das respostas, use comentários `/* */`, como o roteiro. O dono pode usar comentários de linha nos arquivos dele; isso não é erro.
- Termine com as fontes em links.

## Fontes de referência

- Documentação do PostgreSQL: https://www.postgresql.org/docs/current/
- Tutorial oficial: https://www.postgresql.org/docs/current/tutorial.html
- psql (variáveis como `ON_ERROR_ROLLBACK`): https://www.postgresql.org/docs/current/app-psql.html
- Transações: https://www.postgresql.org/docs/current/tutorial-transactions.html
- Sequências (valores não voltam no rollback): https://www.postgresql.org/docs/current/functions-sequence.html
- PostgreSQL Wiki, Don't Do This: https://wiki.postgresql.org/wiki/Don%27t_Do_This
- Pagila: https://github.com/devrimgunduz/pagila

# Roteiro de Estudo: SQL com PostgreSQL, do Zero ao Nível de Entrevista

## Resumo

Este roteiro tem **7 fases e 23 módulos** (do 0 ao 22). Cada módulo traz objetivo, conceitos em ordem atômica (do mais simples ao mais composto), exemplos que você executa, 4 exercícios graduais e um desafio. Ao fim de cada fase há **questões estilo entrevista**. Não há gabarito: você manda as soluções no chat e eu corrijo.

O banco usado é o **Pagila**, um banco de exemplo oficial da comunidade PostgreSQL que simula uma rede de locadoras de filmes. Ele roda no **Docker**, isolado do seu Omarchy, e pode ser apagado e recriado em segundos.

| Fase | Módulos | Foco |
|------|---------|------|
| 0. Ambiente | 0 | Subir o Postgres com o Pagila no Docker e conhecer o `psql` |
| 1. Consultando uma tabela | 1 a 5 | `SELECT`, filtros, `NULL`, ordenação, funções e `CASE` |
| 2. Agregando e juntando | 6 a 9 | `GROUP BY`, `HAVING`, todos os tipos de `JOIN`, `UNION` |
| 3. Consultas intermediárias | 10 a 13 | Subconsultas, CTEs e window functions |
| 4. Criando e alterando dados | 14 a 18 | Tabelas, constraints, modelagem, `INSERT`/`UPDATE`/`DELETE`, transações |
| 5. Organização e performance | 19 e 20 | Views, índices e `EXPLAIN` |
| 6. Projeto final e extra | 21 e 22 | Banco do Gerenciador de Tarefas e integração com TypeScript |

A ordem é "consultar primeiro, criar depois": você aprende a ler dados em um banco pronto (o que entrevistas mais cobram) e só depois aprende a criar suas próprias tabelas.

---

## Como usar este roteiro

1. **Leia os "Conceitos" em ordem.** Cada item depende do anterior.
2. **Digite os exemplos** em vez de copiar e colar. Rode e observe o resultado antes de seguir.
3. **Faça cada exercício em um arquivo `.sql` separado**, por exemplo `modulo-03/ex1.sql`. Assim você tem um histórico do seu progresso.
4. **Antes de rodar, tente prever o resultado.** Quantas linhas vão voltar? Quais colunas? Isso treina o raciocínio que entrevistas avaliam.
5. **Mande suas soluções no chat** para eu corrigir e mostrar alternativas.
6. **Responda as questões de entrevista em voz alta ou por escrito**, como se estivesse explicando para alguém. Depois mande para mim.
7. Use a **Leitura** de cada módulo para aprofundar na documentação oficial.

> Fundamento que vale para o roteiro inteiro: SQL é uma linguagem **declarativa**. Você descreve **o que** quer ("os 10 filmes mais longos"), e o banco decide **como** buscar. Isso é diferente do TypeScript, em que você escreve o passo a passo (loops, condições).

---

# FASE 0: AMBIENTE

## Módulo 0: Preparando o PostgreSQL com o Pagila no Docker

**Objetivo:** ter o PostgreSQL rodando em um container, com o banco Pagila carregado, e saber se conectar a ele.

**Conceitos:**
1. **Banco de dados**: um conjunto organizado de dados guardados de forma persistente.
2. **SGBD** (Sistema Gerenciador de Banco de Dados): o programa que guarda os dados e responde às consultas. O PostgreSQL é um SGBD.
3. **Servidor e cliente**: o PostgreSQL é um **servidor** (fica rodando, esperando pedidos). Você usa um **cliente** (como o `psql`) para mandar comandos SQL a ele.
4. **Tabela**: uma estrutura parecida com uma planilha. Cada **coluna** tem um nome e um tipo. Cada **linha** é um registro.
5. **Database e schema**: um servidor guarda vários *databases* (o nosso se chama `pagila`). Dentro de um database, as tabelas ficam organizadas em *schemas*, que funcionam como pastas. O schema padrão se chama `public`.
6. **Imagem Docker**: um "molde" de um programa já instalado e configurado.
7. **Container**: uma instância rodando de uma imagem, isolada do seu sistema.
8. **Volume**: um espaço de disco que o Docker mantém para o container, para os dados sobreviverem quando o container para.
9. **Porta**: o "número de entrada" do servidor. O PostgreSQL usa a porta `5432` por padrão.
10. **Docker Compose**: um arquivo (`docker-compose.yml`) que descreve um ou mais containers, para subir tudo com um comando só.

### O que o Omarchy já traz

O Omarchy já instala `docker`, `docker-compose` e o `lazydocker` (o atalho do menu Docker abre o lazydocker, um painel no terminal para ver containers). Um detalhe importante: **por segurança, o Omarchy não coloca seu usuário no grupo `docker`**. Por isso os comandos deste roteiro usam `sudo docker`. Existe a opção `Setup > Security > Sudoless Docker` no menu do Omarchy para tirar o `sudo`, mas o próprio Omarchy avisa que isso equivale a dar acesso de root sem senha para qualquer programa rodando como você. Para estudar, manter o `sudo` é o caminho mais seguro.

O menu do Omarchy também tem `Install > Development > Docker DB > PostgreSQL`, que sobe um container `postgres18` vazio na porta 5432. **Não vamos usar essa opção**, porque o Pagila tem seu próprio `docker-compose.yml` que já cria o banco, carrega os dados e instala as extensões que o esquema do Pagila precisa (como a `pgvector`). Se você já tiver instalado o `postgres18` pelo menu, ele ocupa a mesma porta, então pare ele antes (passo 2).

### Passo a passo

**1. Confirme que o Docker responde:**

```bash
sudo docker version
sudo docker ps
```

O segundo comando lista os containers rodando. Se aparecer uma tabela (mesmo vazia), está tudo certo.

**2. Libere a porta 5432 (só se necessário):** se o `docker ps` mostrar um container `postgres18`, pare ele:

```bash
sudo docker stop postgres18
```

**3. Crie a pasta de estudos e baixe o Pagila:**

```bash
mkdir -p ~/Projects/learning-postgresql
cd ~/Projects/learning-postgresql
git clone https://github.com/devrimgunduz/pagila.git
cd pagila
```

**4. Suba os containers:**

```bash
sudo docker compose up -d
```

Na primeira vez, o Docker vai baixar a imagem `postgres:18`, montar uma imagem própria com as extensões e carregar os dados. Isso leva alguns minutos. O `-d` deixa os containers rodando em segundo plano. Esse compose sobe dois containers: `pagila` (o banco) e `pgadmin4` (uma interface web opcional).

**5. Espere a carga dos dados terminar:**

```bash
sudo docker compose logs -f pagila
```

Espere aparecer a mensagem `PostgreSQL init process complete; ready for start up.` e logo depois `database system is ready to accept connections`. Aperte `Ctrl + C` para sair dos logs (o container continua rodando).

**6. Conecte com o `psql`:**

```bash
sudo docker exec -it pagila psql -U postgres -d pagila
```

Leitura atômica desse comando: `docker exec` executa um programa **dentro** do container; `-it` deixa interativo (você digita e vê a resposta); `pagila` é o nome do container; `psql` é o cliente; `-U postgres` é o usuário; `-d pagila` é o database.

O prompt muda para `pagila=#`. Você está dentro do banco.

**7. Teste:**

```sql
SELECT count(*) FROM rental;
```

Na versão testada para este roteiro, o resultado foi `51805`. Se vier um número parecido, o banco está pronto.

### O mapa do Pagila

O Pagila é uma rede de locadoras. As tabelas principais e como se ligam:

```
country <- city <- address <- customer -> rental <- inventory -> film -> language
                       ^          |          |          |          |
                     store        v          v        store    film_actor -> actor
                       |       payment     staff              film_category -> category
                     staff
```

| Tabela | O que guarda |
|--------|--------------|
| `film` | Os filmes do catálogo (1000 filmes): título, duração, preço do aluguel, classificação |
| `actor` | Atores |
| `film_actor` | Qual ator está em qual filme (liga `film` e `actor`) |
| `category` e `film_category` | Categorias (Action, Comedy...) e qual filme está em qual categoria |
| `language` | Idiomas dos filmes |
| `inventory` | As **cópias físicas** de cada filme em cada loja |
| `customer` | Clientes |
| `rental` | Cada aluguel: qual cópia, qual cliente, quando alugou, quando devolveu |
| `payment` | Pagamentos dos aluguéis |
| `staff` e `store` | Funcionários e lojas |
| `address`, `city`, `country` | Endereços, com cidade e país |

Os dados vão de **2022 a julho de 2026**. Por isso, nos exercícios, use datas fixas (como `'2025-01-01'`) em vez de "hoje": se você filtrar "aluguéis dos últimos 30 dias", não vai encontrar nada.

Alguns nomes de cidade aparecem sem as letras acentuadas (como `Belm` em vez de `Belém`). Isso vem dos dados originais do banco, não é erro da sua instalação.

O repositório do Pagila tem um diagrama visual em `pagila-schema-diagram.png`. Abra ele e deixe à mão durante os estudos.

### Comandos do `psql` que você vai usar o tempo todo

Comandos que começam com `\` são do `psql`, não do SQL. Eles não precisam de `;`.

| Comando | O que faz |
|---------|-----------|
| `\dt` | Lista as tabelas |
| `\d film` | Mostra as colunas, tipos, índices e chaves da tabela `film` |
| `\dv` | Lista as views |
| `\x auto` | Mostra resultados largos na vertical, um campo por linha |
| `\timing` | Liga ou desliga a exibição do tempo de cada consulta |
| `\h SELECT` | Ajuda da sintaxe de um comando SQL |
| `\?` | Lista todos os comandos do `psql` |
| `\q` | Sai do `psql` |

Quando o resultado é grande, o `psql` abre um "paginador". Use as setas para navegar e `q` para sair dele.

### Rodando os exercícios a partir de arquivos

Crie suas pastas de exercícios em `~/Projects/learning-postgresql`, fora da pasta `pagila`:

```bash
mkdir -p ~/Projects/learning-postgresql/modulo-01
```

Escreva a consulta no seu editor, salve como `~/Projects/learning-postgresql/modulo-01/ex1.sql` e execute assim:

```bash
cd ~/Projects/learning-postgresql
sudo docker exec -i pagila psql -U postgres -d pagila < modulo-01/ex1.sql
```

Note que aqui é `-i` e não `-it`: o `<` manda o conteúdo do arquivo para dentro do `psql`.

### Comandos do dia a dia

Todos rodados de dentro da pasta `~/Projects/learning-postgresql/pagila`:

| Situação | Comando |
|----------|---------|
| Ligar os containers (por exemplo, depois de reiniciar o PC) | `sudo docker compose start` |
| Desligar os containers | `sudo docker compose stop` |
| Ver se estão rodando | `sudo docker compose ps` |
| **Resetar o banco** (apaga tudo e recarrega o Pagila original) | `sudo docker compose down -v` e depois `sudo docker compose up -d` |

O reset é seu "botão de desfazer". Na Fase 4 você vai alterar dados, e se algo der muito errado é só resetar.

### Interface gráfica (opcional)

O compose também sobe o **pgAdmin**, uma interface web. Abra `http://localhost:5050` no navegador e entre com o e-mail `admin@admin.com` e a senha `root`. O servidor `pagila` já aparece cadastrado; quando ele pedir a senha do banco, use `123456`. O roteiro usa o `psql` como ferramenta principal, porque ele é o que você vai encontrar em servidores e em entrevistas práticas, mas o pgAdmin ajuda a visualizar tabelas.

> As senhas `123456` e `root` vêm do `docker-compose.yml` do Pagila. Elas servem só para estudo local. Nunca use senhas assim em nada exposto à internet.

**Exercício 0.1:** dentro do `psql`, rode `\dt` e conte quantas tabelas aparecem. Depois rode `\d film` e anote: quais colunas a tabela tem? Qual é o tipo da coluna `rental_rate`? Qual coluna é a chave primária?

**Exercício 0.2:** crie o arquivo `modulo-00/teste.sql` com `SELECT count(*) FROM film;`, execute pelo terminal com o comando da seção "Rodando os exercícios" e confirme o resultado.

**Leitura:** [README do Pagila](https://github.com/devrimgunduz/pagila), [Documentação do psql](https://www.postgresql.org/docs/current/app-psql.html), [Tutorial oficial: conceitos](https://www.postgresql.org/docs/current/tutorial-concepts.html)

---

# FASE 1: CONSULTANDO UMA TABELA

## Módulo 1: O primeiro SELECT

**Objetivo:** ler dados de uma tabela escolhendo colunas e criando colunas calculadas.

**Conceitos:**
1. **Consulta (query)**: um pedido de dados ao banco.
2. **`SELECT`**: diz **quais colunas** você quer.
3. **`FROM`**: diz **de qual tabela**.
4. **`;`**: termina o comando. No `psql`, sem o `;` ele fica esperando você continuar.
5. **`*`**: "todas as colunas". Útil para explorar, mas evite em código real, porque traz dados que você não precisa.
6. **Palavras-chave não diferenciam maiúsculas**: `SELECT` e `select` são iguais. A convenção é escrever palavras-chave em maiúsculas para facilitar a leitura.
7. **Aspas simples e duplas**: `'texto'` (aspas simples) é um valor de texto. `"nome"` (aspas duplas) é um nome de coluna ou tabela. Confundir as duas é um erro muito comum.
8. **Expressões**: colunas podem ser calculadas: `rental_rate * 2`.
9. **Alias com `AS`**: dá um nome a uma coluna do resultado.
10. **`DISTINCT`**: remove linhas repetidas do resultado.
11. **`LIMIT`**: limita quantas linhas voltam.
12. **Comentários**: `/* assim */` em qualquer lugar, ou dois hífens seguidos para comentar até o fim da linha. Neste roteiro os exemplos usam `/* */`.

**Exemplo:**

```sql
SELECT title, release_year, rental_rate
FROM film
LIMIT 5;

SELECT title AS titulo,
       rental_rate AS preco_aluguel,
       rental_rate * 2 AS preco_dobrado
FROM film
LIMIT 5;

/* Quais classificações etárias existem? */
SELECT DISTINCT rating
FROM film;
```

**Exercícios:**
1. Liste o primeiro nome e o sobrenome de 10 atores (tabela `actor`).
2. Liste o título, a duração em minutos (`length`) e a duração em horas calculada por você (`length / 60.0`), com os apelidos `titulo`, `minutos` e `horas`.
3. Quais valores distintos existem na coluna `rental_rate`? E na coluna `rental_duration` (dias que o cliente pode ficar com o filme)?
4. Liste o nome de todas as categorias.

**Desafio:** rode `SELECT DISTINCT rating FROM film;` e depois `SELECT DISTINCT rating, rental_rate FROM film;`. Por que a segunda volta muito mais linhas? Escreva em um comentário o que o `DISTINCT` considera "repetido" quando há mais de uma coluna.

**Leitura:** [Tutorial: consultando uma tabela](https://www.postgresql.org/docs/current/tutorial-select.html), [Select lists](https://www.postgresql.org/docs/current/queries-select-lists.html)

---

## Módulo 2: Filtrando linhas com WHERE

**Objetivo:** trazer só as linhas que atendem a uma condição.

**Conceitos:**
1. **`WHERE`**: filtra linhas. Só as linhas em que a condição for verdadeira entram no resultado.
2. **Comparação**: `=`, `<>` (diferente; `!=` também funciona), `<`, `>`, `<=`, `>=`.
3. **Lógicos**: `AND` (as duas condições), `OR` (pelo menos uma), `NOT` (inverte).
4. **Precedência**: o `AND` é avaliado antes do `OR`, como multiplicação antes de soma. Use parênteses para deixar a intenção clara.
5. **`BETWEEN a AND b`**: entre dois valores, **incluindo** as pontas.
6. **`IN (...)`**: o valor está em uma lista.
7. **`LIKE`**: compara texto com um padrão. `%` significa "qualquer sequência de caracteres" e `_` significa "exatamente um caractere".
8. **`ILIKE`**: igual ao `LIKE`, mas ignora maiúsculas e minúsculas. É específico do PostgreSQL.

**Exemplo:**

```sql
SELECT title, rating, length
FROM film
WHERE rating = 'PG-13'
  AND length > 180;

SELECT title, rental_rate
FROM film
WHERE rental_rate IN (0.99, 4.99)
  AND title LIKE 'Z%';

/* Os nomes dos funcionários usam maiúsculas e minúsculas misturadas */
SELECT first_name, last_name
FROM staff
WHERE last_name ILIKE '%son%'
LIMIT 10;
```

**Exercícios:**
1. Liste os filmes com duração entre 60 e 70 minutos usando `BETWEEN`. Depois reescreva usando `>=` e `<=` e confirme que o resultado é igual.
2. Liste os clientes da loja 2 (`store_id`) que estão inativos (`active = 0`).
3. Liste os filmes cujo título contém a palavra `LOVE`.
4. Liste os atores cujo primeiro nome tem **exatamente 3 letras** (dica: `_`).

**Desafio:** escreva duas consultas para "filmes com classificação G ou PG que têm mais de 150 minutos": uma **sem** parênteses (`rating = 'G' OR rating = 'PG' AND length > 150`) e outra **com** parênteses. Compare a quantidade de linhas e explique em um comentário o que a versão sem parênteses realmente pediu.

**Leitura:** [WHERE clause](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-WHERE), [Pattern matching (LIKE)](https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-LIKE)

---

## Módulo 3: O valor NULL

**Objetivo:** entender o "valor desconhecido" do SQL, que é fonte de muitos bugs e de muitas perguntas de entrevista.

**Conceitos:**
1. **`NULL`**: significa "valor ausente ou desconhecido". **Não é zero e não é texto vazio.**
2. **Comparar com `NULL` não funciona com `=`**: `NULL = NULL` não é verdadeiro, é `NULL` (desconhecido). Se você não sabe dois valores, não sabe se são iguais.
3. **`IS NULL` e `IS NOT NULL`**: a forma correta de testar.
4. **Lógica de três valores**: no SQL uma condição pode ser verdadeira, falsa ou **desconhecida**. O `WHERE` só deixa passar as **verdadeiras**.
5. **`COALESCE(a, b, ...)`**: retorna o primeiro valor que não é `NULL`. Parecido com o `??` do TypeScript.
6. **`NULLIF(a, b)`**: retorna `NULL` se `a` for igual a `b`. Útil para transformar texto vazio em `NULL`.
7. **Operações com `NULL` dão `NULL`**: `10 + NULL` é `NULL`.

**Exemplo:**

```sql
/* Aluguéis que ainda não foram devolvidos */
SELECT rental_id, rental_date, return_date
FROM rental
WHERE return_date IS NULL
LIMIT 5;

SELECT NULL = NULL AS igual, NULL IS NULL AS eh_nulo, 10 + NULL AS soma;

/* address2 é o complemento do endereço */
SELECT address, address2, COALESCE(address2, '(nulo)') AS complemento
FROM address
LIMIT 5;
```

Repare que, no último resultado, a coluna `complemento` aparece em branco e não como `(nulo)`. Isso acontece porque, nessas linhas, `address2` não é `NULL`: é um texto vazio. O exercício 1 explora essa diferença.

**Exercícios:**
1. Liste os endereços em que `address2` é `NULL`. Depois liste os endereços em que `address2` é texto vazio (`''`). Qual dos dois casos aparece mais? Isso mostra que `NULL` e `''` são coisas diferentes.
2. Mostre `address` e uma coluna `complemento` que exiba `'sem complemento'` tanto quando `address2` for `NULL` quanto quando for vazio (dica: combine `NULLIF` com `COALESCE`).
3. Rode `SELECT title FROM film WHERE original_language_id = NULL;` e depois troque por `IS NULL`. Explique a diferença de resultado.
4. Liste os aluguéis não devolvidos que foram feitos **antes de 2026**.

**Desafio:** antes de executar, escreva no papel o resultado que você espera para cada coluna desta consulta. Depois rode e compare:

```sql
SELECT NULL AND false AS a,
       NULL AND true  AS b,
       NULL OR true   AS c,
       NULL OR false  AS d,
       NOT NULL       AS e;
```

**Leitura:** [Comparison functions and operators (IS NULL)](https://www.postgresql.org/docs/current/functions-comparison.html), [COALESCE e NULLIF](https://www.postgresql.org/docs/current/functions-conditional.html)

---

## Módulo 4: Ordenação, paginação e a ordem de execução

**Objetivo:** ordenar resultados, paginar e entender em que ordem o banco "lê" uma consulta.

**Conceitos:**
1. **Sem `ORDER BY`, a ordem não é garantida.** O banco pode devolver as linhas em qualquer ordem. Se a ordem importa, peça.
2. **`ORDER BY coluna ASC`** (crescente, o padrão) **ou `DESC`** (decrescente).
3. **Várias colunas**: `ORDER BY length DESC, title` ordena pela duração e usa o título como desempate.
4. **`NULLS FIRST` e `NULLS LAST`**: onde os nulos aparecem. No PostgreSQL, em `ASC` os nulos ficam por último e em `DESC` ficam primeiro.
5. **`LIMIT n OFFSET m`**: pula `m` linhas e traz `n`. É a forma clássica de paginação.
6. **Ordem lógica de execução**: você **escreve** `SELECT ... FROM ... WHERE ... ORDER BY ... LIMIT`, mas o banco **processa** nesta ordem:
   1. `FROM` (de onde vêm os dados)
   2. `WHERE` (filtra linhas)
   3. `SELECT` (calcula as colunas e os apelidos)
   4. `DISTINCT`
   5. `ORDER BY`
   6. `LIMIT` / `OFFSET`
7. **Consequência**: um apelido criado no `SELECT` **pode** ser usado no `ORDER BY` (que vem depois), mas **não** no `WHERE` (que vem antes).

**Exemplo:**

```sql
SELECT title, length
FROM film
ORDER BY length DESC, title
LIMIT 10;

/* Segunda "página" de 10 */
SELECT title, length
FROM film
ORDER BY length DESC, title
LIMIT 10 OFFSET 10;

SELECT title, length / 60.0 AS horas
FROM film
ORDER BY horas DESC
LIMIT 3;

SELECT rental_id, return_date
FROM rental
ORDER BY return_date DESC NULLS LAST
LIMIT 5;
```

**Exercícios:**
1. Liste os 5 filmes com maior custo de reposição (`replacement_cost`), usando o título como desempate.
2. Mostre a **terceira página** da lista de clientes ordenada por sobrenome e nome, com 20 clientes por página.
3. Tente usar o apelido `horas` do exemplo dentro de um `WHERE horas > 3`. Leia o erro e explique por que ele acontece usando a ordem de execução.
4. Liste os 10 aluguéis mais recentes (`rental_date`).

**Desafio (clássico de entrevista):** encontre o **segundo maior valor distinto** de `replacement_cost`, usando apenas `DISTINCT`, `ORDER BY`, `LIMIT` e `OFFSET`.

**Leitura:** [Sorting rows (ORDER BY)](https://www.postgresql.org/docs/current/queries-order.html), [LIMIT e OFFSET](https://www.postgresql.org/docs/current/queries-limit.html)

---

## Módulo 5: Funções, conversão de tipos e CASE

**Objetivo:** transformar valores dentro da consulta: textos, números e datas.

**Conceitos:**
1. **Função**: recebe valores e devolve um valor, como em qualquer linguagem.
2. **Texto**: `||` concatena, `UPPER`, `LOWER`, `INITCAP` (primeira letra maiúscula), `LENGTH`, `TRIM`, `REPLACE`, `SUBSTRING`, `SPLIT_PART`.
3. **Números**: `ROUND(x, casas)`, `CEIL`, `FLOOR`, `ABS`.
4. **Divisão inteira**: `7 / 2` dá `3`, porque inteiro dividido por inteiro dá inteiro. Use `7 / 2.0` para ter decimal. Esse detalhe derruba muita gente.
5. **Conversão de tipo (cast)**: `valor::tipo`, por exemplo `'2025-01-01'::date` ou `rental_date::date`. A forma padrão do SQL é `CAST(valor AS tipo)`.
6. **Datas e horas**:
   - `now()` e `current_date`: agora e hoje.
   - `EXTRACT(YEAR FROM data)`: pega uma parte da data.
   - `DATE_TRUNC('month', data)`: "arredonda" para o início do mês.
   - `interval '7 days'`: um intervalo de tempo. `data + interval '7 days'` soma.
   - `data2 - data1`: diferença (entre `date` dá dias; entre `timestamp` dá um `interval`).
   - `TO_CHAR(data, 'DD/MM/YYYY')`: formata como texto.
7. **Filtro de período**: prefira `data >= '2025-12-01' AND data < '2026-01-01'` a `BETWEEN`, porque o `BETWEEN` inclui a ponta final e erra com horários.
8. **`CASE`**: o "if" do SQL. Avalia condições em ordem e devolve o valor da primeira verdadeira.

**Exemplo:**

```sql
SELECT first_name || ' ' || last_name AS nome_completo,
       LOWER(email) AS email,
       LENGTH(first_name) AS letras_no_nome
FROM customer
LIMIT 5;

SELECT 7 / 2 AS divisao_inteira,
       7 / 2.0 AS divisao_decimal,
       ROUND(7 / 3.0, 2) AS arredondado;

SELECT rental_date,
       rental_date::date AS so_a_data,
       EXTRACT(YEAR FROM rental_date) AS ano,
       DATE_TRUNC('month', rental_date) AS inicio_do_mes,
       TO_CHAR(rental_date, 'DD/MM/YYYY') AS formatada,
       return_date - rental_date AS tempo_com_o_cliente
FROM rental
LIMIT 5;

SELECT title, length,
       CASE
         WHEN length < 60 THEN 'curto'
         WHEN length <= 120 THEN 'médio'
         ELSE 'longo'
       END AS faixa
FROM film
LIMIT 10;
```

**Exercícios:**
1. Mostre o nome dos clientes no formato `Smith, Mary` (sobrenome, vírgula, nome, com só a primeira letra maiúscula).
2. Mostre o e-mail dos funcionários (`staff`) e, em outra coluna, só o domínio (a parte depois do `@`). Dica: `SPLIT_PART`.
3. Liste os aluguéis feitos em dezembro de 2025, usando o filtro de período do conceito 7.
4. Classifique os filmes pelo preço de aluguel com `CASE`: `0.99` é "promoção", `2.99` é "normal" e `4.99` é "lançamento".

**Desafio:** para os aluguéis já devolvidos, calcule quantos **dias** cada um ficou com o cliente (dica: converta as duas datas para `date` antes de subtrair). Mostre os 10 mais longos.

**Leitura:** [String functions](https://www.postgresql.org/docs/current/functions-string.html), [Date/time functions](https://www.postgresql.org/docs/current/functions-datetime.html), [CASE](https://www.postgresql.org/docs/current/functions-conditional.html#FUNCTIONS-CASE)

---

## Questões de entrevista da Fase 1

1. Qual é a diferença entre `WHERE coluna = NULL` e `WHERE coluna IS NULL`? Por que a primeira nunca retorna linhas?
2. Explique a ordem lógica de execução de uma consulta com `SELECT`, `FROM`, `WHERE`, `ORDER BY` e `LIMIT`. Por que não dá para usar um apelido do `SELECT` no `WHERE`?
3. Se eu não usar `ORDER BY`, as linhas vêm na ordem em que foram inseridas? Justifique.
4. Escreva uma consulta que retorne o segundo maior salário de uma tabela `funcionario(nome, salario)`. Ela funciona se dois funcionários tiverem o maior salário?
5. Quanto é `SELECT 5 / 2;` no PostgreSQL? E `SELECT 5 / 2.0;`? Por quê?
6. Qual é a diferença entre `LIKE` e `ILIKE`?

---

# FASE 2: AGREGANDO E JUNTANDO

## Módulo 6: Agregação com GROUP BY e HAVING

**Objetivo:** resumir muitas linhas em números: totais, médias, contagens por grupo.

**Conceitos:**
1. **Função de agregação**: recebe várias linhas e devolve um valor só: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`.
2. **`COUNT(*)`** conta linhas. **`COUNT(coluna)`** conta só as linhas em que a coluna **não é `NULL`**. **`COUNT(DISTINCT coluna)`** conta valores diferentes.
3. **Agregações ignoram `NULL`** (com exceção do `COUNT(*)`).
4. **`GROUP BY`**: divide as linhas em grupos e calcula a agregação **para cada grupo**.
5. **A regra de ouro**: com `GROUP BY`, toda coluna do `SELECT` precisa estar no `GROUP BY` **ou** dentro de uma função de agregação. Se não, o banco não sabe qual valor mostrar.
6. **`HAVING`**: filtra **grupos**, depois da agregação. O `WHERE` filtra **linhas**, antes.
7. **Ordem de execução completa**: `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, `DISTINCT`, `ORDER BY`, `LIMIT`.
8. **`FILTER`**: `COUNT(*) FILTER (WHERE amount = 0)` agrega só parte das linhas. É um atalho do PostgreSQL muito útil.

**Exemplo:**

```sql
SELECT COUNT(*) AS total_filmes,
       ROUND(AVG(length), 1) AS duracao_media,
       MIN(rental_rate) AS menor_preco,
       MAX(rental_rate) AS maior_preco
FROM film;

SELECT COUNT(*) AS alugueis,
       COUNT(return_date) AS devolvidos,
       COUNT(DISTINCT customer_id) AS clientes_diferentes
FROM rental;

SELECT rating,
       COUNT(*) AS quantidade,
       ROUND(AVG(length), 1) AS duracao_media
FROM film
GROUP BY rating
ORDER BY quantidade DESC;

SELECT customer_id,
       SUM(amount) AS total_pago,
       COUNT(*) FILTER (WHERE amount = 0) AS pagamentos_zerados
FROM payment
GROUP BY customer_id
HAVING SUM(amount) > 300
ORDER BY total_pago DESC;
```

**Exercícios:**
1. Quantos clientes existem por valor de `active`?
2. Mostre o total arrecadado (`payment.amount`) por ano.
3. Liste os clientes (`customer_id`) que fizeram mais de 80 aluguéis.
4. Quais classificações (`rating`) têm duração média acima de 115 minutos? Use `HAVING`.

**Desafio (clássico de entrevista):** encontre **atores duplicados**, ou seja, combinações de `first_name` e `last_name` que aparecem mais de uma vez na tabela `actor`. Depois tente o mesmo raciocínio com e-mails de clientes.

**Leitura:** [Tutorial: aggregate functions](https://www.postgresql.org/docs/current/tutorial-agg.html), [GROUP BY e HAVING](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-GROUP), [Aggregate functions](https://www.postgresql.org/docs/current/functions-aggregate.html)

---

## Módulo 7: JOIN parte 1, chaves e INNER JOIN

**Objetivo:** combinar dados de várias tabelas relacionadas.

**Conceitos:**
1. **Por que os dados são separados em tabelas**: para não repetir informação. O nome do idioma fica uma vez em `language`, e o filme guarda só o número (`language_id`).
2. **Chave primária (primary key)**: a coluna que identifica cada linha de forma única, como `film.film_id`.
3. **Chave estrangeira (foreign key)**: uma coluna que **aponta** para a chave primária de outra tabela, como `film.language_id` apontando para `language.language_id`. Use `\d film` para ver as chaves estrangeiras listadas em "Foreign-key constraints".
4. **`INNER JOIN ... ON condição`**: junta as linhas das duas tabelas em que a condição é verdadeira. Linhas **sem par** ficam de fora. `JOIN` sozinho significa `INNER JOIN`.
5. **Alias de tabela**: `FROM film AS f` (ou só `film f`) deixa a consulta mais curta.
6. **Coluna ambígua**: se duas tabelas têm uma coluna com o mesmo nome, você precisa dizer de qual tabela: `f.film_id`.
7. **Vários JOINs**: você pode encadear quantos precisar, seguindo o caminho das chaves.
8. **`USING (coluna)`**: atalho quando a coluna tem o mesmo nome nas duas tabelas.
9. **Tabela de ligação**: `film_actor` não tem dados próprios, só liga `film` a `actor`. Para ir de um filme aos atores, você passa por ela.

**Exemplo:**

```sql
SELECT f.title, l.name AS idioma
FROM film AS f
INNER JOIN language AS l ON l.language_id = f.language_id
LIMIT 5;

SELECT c.name AS categoria, COUNT(*) AS filmes
FROM film_category AS fc
JOIN category AS c ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY filmes DESC;

/* Clientes do Brasil: customer -> address -> city -> country */
SELECT cu.first_name, cu.last_name, ci.city
FROM customer cu
JOIN address a ON a.address_id = cu.address_id
JOIN city ci ON ci.city_id = a.city_id
JOIN country co ON co.country_id = ci.country_id
WHERE co.country = 'Brazil'
ORDER BY ci.city;
```

**Exercícios:**
1. Liste o nome dos atores do filme `ACADEMY DINOSAUR`.
2. Liste todos os filmes em que `PENELOPE GUINESS` atuou, em ordem alfabética.
3. Mostre os 10 clientes que mais pagaram, com nome, sobrenome e total pago.
4. Mostre a quantidade de clientes por país, do maior para o menor, só os 10 primeiros.

**Desafio:** calcule o **faturamento por categoria**. O caminho é `payment -> rental -> inventory -> film -> film_category -> category`. Depois responda em um comentário: um filme pode estar em mais de uma categoria? Se sim, o que isso faz com a soma total quando você soma o faturamento de todas as categorias? Compare com `SELECT SUM(amount) FROM payment;`.

**Leitura:** [Tutorial: joins between tables](https://www.postgresql.org/docs/current/tutorial-join.html), [Joined tables](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-JOIN)

---

## Módulo 8: JOIN parte 2, LEFT JOIN e companhia

**Objetivo:** juntar tabelas mantendo linhas sem par, e entender as armadilhas mais comuns.

**Conceitos:**
1. **`LEFT JOIN`**: mantém **todas** as linhas da tabela da esquerda. Quando não há par na direita, as colunas da direita vêm como `NULL`.
2. **Anti-join**: `LEFT JOIN ... WHERE direita.id IS NULL` encontra as linhas **sem** correspondência ("filmes que não têm cópia", "clientes que nunca alugaram").
3. **`RIGHT JOIN`**: o espelho do `LEFT`. Quase ninguém usa: basta inverter a ordem das tabelas e usar `LEFT`.
4. **`FULL JOIN`**: mantém as linhas sem par dos **dois** lados.
5. **`CROSS JOIN`**: combina **cada** linha de uma com **cada** linha da outra (produto cartesiano). 3 linhas com 4 linhas dão 12.
6. **Self join**: juntar uma tabela com ela mesma, usando dois apelidos diferentes.
7. **Armadilha do filtro**: em um `LEFT JOIN`, uma condição sobre a tabela da direita colocada no `WHERE` elimina as linhas com `NULL` e transforma o resultado, na prática, em um `INNER JOIN`. Para filtrar a direita **mantendo** as linhas sem par, coloque a condição no `ON`.
8. **Multiplicação de linhas (fan-out)**: se uma linha da esquerda tem 5 pares na direita, ela aparece 5 vezes. Somar valores da esquerda depois disso infla o resultado.

**Exemplo:**

```sql
/* Filmes que não têm nenhuma cópia no estoque */
SELECT f.film_id, f.title
FROM film f
LEFT JOIN inventory i ON i.film_id = f.film_id
WHERE i.inventory_id IS NULL;

/* Self join: pares de atores com o mesmo sobrenome */
SELECT a1.first_name || ' ' || a1.last_name AS ator_1,
       a2.first_name || ' ' || a2.last_name AS ator_2
FROM actor a1
JOIN actor a2 ON a2.last_name = a1.last_name
             AND a2.actor_id > a1.actor_id
ORDER BY a1.last_name
LIMIT 10;

/* Armadilha: compare a quantidade de linhas das duas consultas */
SELECT c.customer_id, COUNT(r.rental_id) AS alugueis_em_2026
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
WHERE r.rental_date >= '2026-01-01'
GROUP BY c.customer_id;

SELECT c.customer_id, COUNT(r.rental_id) AS alugueis_em_2026
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
                  AND r.rental_date >= '2026-01-01'
GROUP BY c.customer_id;
```

**Exercícios:**
1. Liste os clientes que nunca fizeram nenhum aluguel.
2. Liste os filmes que não têm nenhum ator cadastrado.
3. Liste **todos** os filmes com a quantidade de cópias em estoque, mostrando `0` para os que não têm cópia. (Dica: `COUNT(coluna)` em vez de `COUNT(*)`. Por quê?)
4. Use `CROSS JOIN` para gerar todas as combinações entre as lojas 1 e 2 e as 16 categorias. Quantas linhas devem voltar?

**Desafio:** encontre os aluguéis que **não têm pagamento** registrado. Depois, escreva em um comentário por que o primeiro "exemplo da armadilha" retornou menos clientes do que o segundo.

**Leitura:** [Joined tables (tipos de JOIN)](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-JOIN)

---

## Módulo 9: Operadores de conjunto (UNION, INTERSECT, EXCEPT)

**Objetivo:** combinar resultados de consultas diferentes empilhando, cruzando ou subtraindo linhas.

**Conceitos:**
1. **JOIN junta colunas lado a lado. Operadores de conjunto empilham linhas** uma embaixo da outra.
2. **Regra**: as consultas precisam ter o **mesmo número de colunas**, com tipos compatíveis. Os nomes das colunas vêm da primeira consulta.
3. **`UNION`**: junta e **remove duplicatas**.
4. **`UNION ALL`**: junta **mantendo** duplicatas. É mais rápido, porque não precisa comparar. Use quando não houver duplicatas ou quando elas importarem.
5. **`INTERSECT`**: só as linhas que aparecem nas duas consultas.
6. **`EXCEPT`**: as linhas da primeira que **não** aparecem na segunda.
7. **`ORDER BY` e `LIMIT`** no final valem para o resultado inteiro.

**Exemplo:**

```sql
SELECT first_name, last_name, 'ator' AS origem FROM actor
UNION ALL
SELECT first_name, last_name, 'cliente' FROM customer
ORDER BY last_name
LIMIT 10;

/* Primeiros nomes que existem tanto entre atores quanto entre clientes */
SELECT first_name FROM actor
INTERSECT
SELECT first_name FROM customer
ORDER BY first_name;

/* Filmes sem cópia, agora com EXCEPT */
SELECT film_id FROM film
EXCEPT
SELECT film_id FROM inventory;
```

**Exercícios:**
1. Conte quantas linhas retornam `SELECT first_name FROM actor UNION SELECT first_name FROM customer` e a mesma consulta com `UNION ALL`. Explique a diferença.
2. Liste os primeiros nomes de atores que **não** aparecem entre os clientes.
3. Refaça o exercício "clientes que nunca alugaram" (módulo 8) usando `EXCEPT`. Qual versão traz o nome do cliente com mais facilidade?
4. Tente fazer um `UNION` entre `SELECT title FROM film` e `SELECT film_id FROM film`. Leia o erro.

**Desafio:** monte uma "lista de contatos" com nome completo, e-mail e uma coluna `origem` (`cliente` ou `funcionario`), unindo `customer` e `staff`. Ordene por e-mail e mostre os 20 primeiros.

**Leitura:** [Combining queries (UNION, INTERSECT, EXCEPT)](https://www.postgresql.org/docs/current/queries-union.html)

---

## Questões de entrevista da Fase 2

1. Qual é a diferença entre `WHERE` e `HAVING`? Dê um exemplo em que só o `HAVING` resolve.
2. Qual é a diferença entre `COUNT(*)`, `COUNT(coluna)` e `COUNT(DISTINCT coluna)`?
3. Explique `INNER JOIN` e `LEFT JOIN` para alguém que não programa. Quando o resultado dos dois é igual?
4. Dadas `cliente(id, nome)` e `pedido(id, cliente_id)`, escreva duas formas diferentes de listar os clientes sem pedidos.
5. Qual é a diferença entre `UNION` e `UNION ALL`? Qual é mais rápido e por quê?
6. Como você encontraria registros duplicados em uma tabela?
7. Por que este SQL dá erro: `SELECT nome, COUNT(*) FROM cliente GROUP BY cidade;`?

---

# FASE 3: CONSULTAS INTERMEDIÁRIAS

## Módulo 10: Subconsultas

**Objetivo:** usar o resultado de uma consulta dentro de outra.

**Conceitos:**
1. **Subconsulta**: uma consulta entre parênteses dentro de outra.
2. **Escalar**: devolve **um valor só** (uma linha, uma coluna). Pode ser usada onde caberia um número: `WHERE length > (SELECT AVG(length) FROM film)`.
3. **Com `IN`**: devolve uma lista de valores para comparar.
4. **`EXISTS`**: verdadeiro se a subconsulta devolver **pelo menos uma linha**. O que ela seleciona não importa, por isso a convenção `SELECT 1`.
5. **`NOT EXISTS`**: a forma mais segura de fazer "não existe correspondente".
6. **Correlacionada**: a subconsulta usa uma coluna da consulta de fora. Ela é avaliada, conceitualmente, uma vez para cada linha de fora.
7. **No `FROM` (tabela derivada)**: o resultado da subconsulta vira uma tabela temporária, que precisa de um apelido.
8. **Armadilha do `NOT IN` com `NULL`**: se a lista da subconsulta tiver um `NULL`, o `NOT IN` não retorna **nada**. Prefira `NOT EXISTS`.

**Exemplo:**

```sql
/* Escalar: filmes acima da duração média */
SELECT title, length
FROM film
WHERE length > (SELECT AVG(length) FROM film)
ORDER BY length
LIMIT 5;

/* EXISTS correlacionado: clientes com algum aluguel em aberto */
SELECT c.first_name, c.last_name
FROM customer c
WHERE EXISTS (
  SELECT 1 FROM rental r
  WHERE r.customer_id = c.customer_id
    AND r.return_date IS NULL
)
LIMIT 5;

/* No FROM: média do total gasto por cliente */
SELECT ROUND(AVG(total), 2) AS media_por_cliente
FROM (
  SELECT customer_id, SUM(amount) AS total
  FROM payment
  GROUP BY customer_id
) AS totais;

/* A armadilha do NOT IN: esta consulta não retorna nenhuma linha */
SELECT 'apareceu' WHERE 3 NOT IN (1, 2, NULL);
```

**Exercícios:**
1. Liste os filmes cujo `replacement_cost` é igual ao maior `replacement_cost` do catálogo.
2. Liste os clientes que **nunca** alugaram um filme da categoria `Horror` (use `NOT EXISTS`).
3. Para cada filme, mostre o título e a quantidade de atores, usando uma subconsulta escalar no `SELECT`.
4. Liste os filmes que têm **mais atores do que a média** de atores por filme.

**Desafio:** liste os clientes cujo total pago é maior que a média do total pago **pelos clientes da mesma loja** (`store_id`). Isso exige uma subconsulta correlacionada.

**Leitura:** [Subquery expressions (EXISTS, IN)](https://www.postgresql.org/docs/current/functions-subquery.html), [Postgres Wiki: Don't use NOT IN](https://wiki.postgresql.org/wiki/Don%27t_Do_This#Don.27t_use_NOT_IN)

---

## Módulo 11: CTEs (a cláusula WITH)

**Objetivo:** escrever consultas longas de forma legível, em etapas com nome.

**Conceitos:**
1. **CTE (Common Table Expression)**: uma consulta com nome, definida com `WITH nome AS (...)`, que pode ser usada logo abaixo como se fosse uma tabela.
2. **Várias CTEs**: separe com vírgula. Uma pode usar a anterior.
3. **Por que usar**: legibilidade. Você lê de cima para baixo, como passos de uma receita, em vez de subconsultas aninhadas de dentro para fora.
4. **CTE e subconsulta no `FROM` resolvem os mesmos problemas.** Escolha a que fica mais clara.
5. **`WITH RECURSIVE`**: uma CTE que referencia ela mesma, usada para hierarquias (organogramas, categorias com subcategorias). Basta saber que existe; o exemplo mostra a ideia.
6. **`generate_series`**: função do PostgreSQL que gera uma sequência de números ou datas. Muito útil para preencher "buracos" (meses sem venda, por exemplo).

**Exemplo:**

```sql
WITH total_por_cliente AS (
  SELECT customer_id, SUM(amount) AS total
  FROM payment
  GROUP BY customer_id
),
media AS (
  SELECT AVG(total) AS valor FROM total_por_cliente
)
SELECT c.first_name, c.last_name, t.total
FROM total_por_cliente t
JOIN customer c USING (customer_id)
CROSS JOIN media m
WHERE t.total > m.valor * 1.5
ORDER BY t.total DESC
LIMIT 10;

/* Recursiva: conta de 1 a 5 */
WITH RECURSIVE contador AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM contador WHERE n < 5
)
SELECT n FROM contador;

/* Os 12 meses de 2025, gerados sem tabela nenhuma */
SELECT generate_series('2025-01-01'::date, '2025-12-01'::date, interval '1 month')::date AS mes;
```

**Exercícios:**
1. Reescreva o desafio do módulo 10 usando CTEs.
2. Com uma CTE, calcule o faturamento de cada mês de 2025 e, na consulta final, mostre só o mês com maior faturamento.
3. Com duas CTEs, calcule a quantidade de aluguéis por categoria e mostre as categorias acima da média.
4. Use `generate_series` para listar todos os dias de janeiro de 2026 com a quantidade de aluguéis de cada dia, incluindo dias com zero (dica: `LEFT JOIN`).

**Desafio:** compare o faturamento de cada mês de 2025 com a **média mensal** do próprio ano, mostrando uma coluna `acima_da_media` com `sim` ou `não`.

**Leitura:** [WITH queries (CTEs)](https://www.postgresql.org/docs/current/queries-with.html), [generate_series](https://www.postgresql.org/docs/current/functions-srf.html)

---

## Módulo 12: Window functions parte 1, rankings

**Objetivo:** fazer cálculos "olhando para outras linhas" sem perder o detalhe de cada linha. É um dos assuntos mais cobrados em entrevistas de SQL.

**Conceitos:**
1. **O problema**: o `GROUP BY` "esmaga" as linhas em uma por grupo. Às vezes você quer manter cada linha **e** ver um valor do grupo ao lado (a média da categoria, a posição no ranking).
2. **Window function**: uma função seguida de `OVER (...)`. A "janela" é o conjunto de linhas que ela enxerga.
3. **`OVER ()`** vazio: a janela é o resultado inteiro.
4. **`PARTITION BY`**: divide a janela em grupos, como o `GROUP BY`, mas **sem juntar as linhas**.
5. **`ORDER BY` dentro do `OVER`**: define a ordem dentro de cada grupo.
6. **`ROW_NUMBER()`**: numera 1, 2, 3, 4, sem empates.
7. **`RANK()`**: empates recebem a mesma posição e **pulam** a próxima: 1, 2, 2, 4.
8. **`DENSE_RANK()`**: empates recebem a mesma posição **sem pular**: 1, 2, 2, 3.
9. **Agregações como janela**: `AVG(length) OVER (PARTITION BY rating)` mostra a média da classificação em cada linha.
10. **Window functions rodam depois do `WHERE` e do `GROUP BY`**, por isso não podem ser filtradas no `WHERE`. Para filtrar pelo ranking, use uma CTE ou subconsulta.

**Exemplo:**

```sql
/* Compare as três numerações */
SELECT title, length,
       ROW_NUMBER() OVER (ORDER BY length DESC) AS row_number,
       RANK()       OVER (ORDER BY length DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY length DESC) AS dense_rank
FROM film
ORDER BY length DESC
LIMIT 12;

/* Cada filme ao lado da média da sua classificação */
SELECT title, rating, length,
       ROUND(AVG(length) OVER (PARTITION BY rating), 1) AS media_da_classificacao
FROM film
LIMIT 5;

/* Top 3 filmes mais longos de cada classificação */
WITH ranqueado AS (
  SELECT title, rating, length,
         ROW_NUMBER() OVER (PARTITION BY rating ORDER BY length DESC, title) AS posicao
  FROM film
)
SELECT rating, posicao, title, length
FROM ranqueado
WHERE posicao <= 3
ORDER BY rating, posicao;
```

**Exercícios:**
1. Para cada filme, mostre a duração, a média da sua classificação e a diferença entre as duas.
2. Mostre os 3 clientes que mais pagaram **em cada loja** (`customer.store_id`).
3. Faça um ranking dos filmes por `replacement_cost` com `RANK` e com `DENSE_RANK`, lado a lado. Em que posição está o primeiro filme de cada um após o primeiro grupo de empates?
4. Use `ROW_NUMBER() OVER (PARTITION BY first_name, last_name ...)` na tabela `actor` para encontrar as linhas duplicadas (as que recebem número maior que 1). Compare com o desafio do módulo 6.

**Desafio:** encontre **o filme mais alugado de cada categoria**. Pense em empates: se dois filmes empatarem em primeiro, sua consulta mostra os dois? Qual função de ranking resolve isso?

**Leitura:** [Tutorial: window functions](https://www.postgresql.org/docs/current/tutorial-window.html), [Window functions (lista)](https://www.postgresql.org/docs/current/functions-window.html)

---

## Módulo 13: Window functions parte 2, LAG, LEAD e acumulados

**Objetivo:** comparar uma linha com a anterior ou a próxima e calcular totais acumulados e médias móveis.

**Conceitos:**
1. **`LAG(coluna)`**: o valor da linha **anterior** na janela. **`LEAD(coluna)`**: o da **próxima**.
2. **Variação**: `valor - LAG(valor)` mostra o crescimento em relação ao período anterior.
3. **Total acumulado (running total)**: `SUM(valor) OVER (ORDER BY data)`.
4. **Percentual do total**: `valor / SUM(valor) OVER ()`.
5. **Frame**: quais linhas, ao redor da atual, entram no cálculo. Exemplo: `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` (a atual e as duas anteriores), usado para média móvel.
6. **Frame padrão**: quando há `ORDER BY` no `OVER`, o padrão é "do início até a linha atual, incluindo linhas **empatadas** com ela". Com datas repetidas, isso pode surpreender. Declarar `ROWS` deixa explícito.
7. **`FIRST_VALUE` e `LAST_VALUE`**: o primeiro e o último valor da janela.

**Exemplo:**

```sql
WITH mensal AS (
  SELECT DATE_TRUNC('month', payment_date)::date AS mes,
         SUM(amount) AS faturamento
  FROM payment
  WHERE payment_date >= '2025-01-01' AND payment_date < '2026-01-01'
  GROUP BY 1
)
SELECT mes,
       faturamento,
       LAG(faturamento) OVER (ORDER BY mes) AS mes_anterior,
       faturamento - LAG(faturamento) OVER (ORDER BY mes) AS variacao,
       SUM(faturamento) OVER (ORDER BY mes) AS acumulado_no_ano,
       ROUND(AVG(faturamento) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movel_3m,
       ROUND(100 * faturamento / SUM(faturamento) OVER (), 2) AS pct_do_ano
FROM mensal
ORDER BY mes;
```

O `GROUP BY 1` agrupa pela primeira coluna do `SELECT`. É um atalho comum, mas em código de produção prefira repetir a expressão ou usar o nome.

**Exercícios:**
1. Para o cliente 1, liste seus aluguéis em ordem de data com uma coluna mostrando quantos dias se passaram desde o aluguel anterior (`LAG`).
2. Mostre a variação **percentual** do faturamento mês a mês em 2025.
3. Para cada cliente, mostre o título do **primeiro** e do **último** filme que ele alugou (dica: `ROW_NUMBER` em uma CTE, ou `FIRST_VALUE`).
4. Calcule o total acumulado de aluguéis por dia em janeiro de 2026.

**Desafio:** para cada cliente, calcule o **intervalo médio em dias entre aluguéis consecutivos** e liste os 10 clientes mais frequentes (menor intervalo médio).

**Leitura:** [Window function calls (frames)](https://www.postgresql.org/docs/current/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS), [Window functions (lista)](https://www.postgresql.org/docs/current/functions-window.html)

---

## Questões de entrevista da Fase 3

1. Qual é a diferença entre `ROW_NUMBER`, `RANK` e `DENSE_RANK`? Dê um exemplo com empate.
2. Como você retorna o top 3 de vendas de cada região? Escreva a consulta.
3. Qual é a diferença entre uma window function e um `GROUP BY`?
4. Por que `WHERE id NOT IN (SELECT cliente_id FROM pedido)` pode retornar zero linhas mesmo havendo clientes sem pedido? Como corrigir?
5. Quando você usaria uma CTE em vez de uma subconsulta?
6. Como calcular um total acumulado de vendas por dia?
7. Como comparar as vendas de cada mês com as do mês anterior?

---

# FASE 4: CRIANDO E ALTERANDO DADOS

> A partir daqui você vai criar e alterar coisas. Para não misturar seu trabalho com o Pagila, crie suas tabelas no schema `estudos` (uma "pasta" separada). Se algo der muito errado, você pode apagar só o seu schema com `DROP SCHEMA estudos CASCADE;` ou resetar tudo com o comando de reset do módulo 0.

## Módulo 14: Tipos de dados e CREATE TABLE

**Objetivo:** criar suas próprias tabelas escolhendo bem os tipos de cada coluna.

**Conceitos:**
1. **DDL (Data Definition Language)**: os comandos que definem a **estrutura** (`CREATE`, `ALTER`, `DROP`). Os que mexem nos **dados** são DML (módulo 17).
2. **`CREATE SCHEMA`**: cria uma "pasta" para tabelas.
3. **Tipos inteiros**: `integer` (até cerca de 2,1 bilhões) e `bigint` (muito maior).
4. **`numeric(p, s)`**: decimal **exato**, com `p` dígitos no total e `s` depois da vírgula. **Use para dinheiro.**
5. **`real` e `double precision`**: ponto flutuante, **aproximados**. Bons para medições científicas, ruins para dinheiro (`0.1 + 0.2` não é exatamente `0.3`).
6. **`text`**: texto de qualquer tamanho. No PostgreSQL, `text` e `varchar(n)` têm o mesmo desempenho; o `varchar(n)` só adiciona um limite.
7. **`boolean`**: `true` ou `false`.
8. **`date`**, **`timestamp`** e **`timestamptz`**: data; data e hora; data e hora **com fuso**. Prefira `timestamptz` para registrar quando algo aconteceu.
9. **Chave primária automática**: `id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY` faz o banco gerar 1, 2, 3... sozinho. É a forma moderna; o `serial` é a forma antiga, que você ainda vai ver em projetos (o próprio Pagila usa sequências).
10. **`DEFAULT`**: valor usado quando o `INSERT` não informa a coluna.
11. **`INSERT` básico**: `INSERT INTO tabela (colunas) VALUES (valores);` (o módulo 17 aprofunda).
12. **`ALTER TABLE`**: adiciona, remove ou renomeia colunas. **`DROP TABLE`**: apaga a tabela inteira.

**Exemplo:**

```sql
CREATE SCHEMA IF NOT EXISTS estudos;

CREATE TABLE estudos.produto (
  id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome       text NOT NULL,
  preco      numeric(10, 2) NOT NULL,
  ativo      boolean NOT NULL DEFAULT true,
  criado_em  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO estudos.produto (nome, preco) VALUES ('Caneta', 2.50);
INSERT INTO estudos.produto (nome, preco) VALUES ('Caderno', 18.90);
SELECT * FROM estudos.produto;

ALTER TABLE estudos.produto ADD COLUMN descricao text;
ALTER TABLE estudos.produto RENAME COLUMN descricao TO detalhes;

/* Por que não usar ponto flutuante para dinheiro */
SELECT 0.1::double precision + 0.2::double precision = 0.3 AS com_float,
       0.1::numeric + 0.2::numeric = 0.3 AS com_numeric;

DROP TABLE estudos.produto;
```

Depois de criar a tabela, rode `\d estudos.produto` no `psql` para ver a estrutura.

**Exercícios:**
1. Crie `estudos.livro` com id automático, título, autor, ano de publicação, preço e se está disponível (padrão `true`).
2. Insira 3 livros, informando só título, autor, ano e preço. Confira que o id e a disponibilidade foram preenchidos sozinhos.
3. Adicione uma coluna `isbn` do tipo `text`. Depois remova a coluna (`DROP COLUMN`).
4. Tente inserir um livro com o id `100` informado por você. Leia o erro e explique o que o `ALWAYS` do `GENERATED ALWAYS` está protegendo.

**Desafio:** crie a tabela `estudos.evento(nome text, momento_sem_fuso timestamp, momento_com_fuso timestamptz)`, insira uma linha com `now()` nas duas colunas e mostre o resultado. Depois rode `SET TIME ZONE 'Asia/Tokyo';`, consulte de novo e explique o que mudou e o que não mudou.

**Leitura:** [Data types](https://www.postgresql.org/docs/current/datatype.html), [Tutorial: creating a new table](https://www.postgresql.org/docs/current/tutorial-table.html), [Identity columns](https://www.postgresql.org/docs/current/ddl-identity-columns.html), [Postgres Wiki: Don't Do This (tipos)](https://wiki.postgresql.org/wiki/Don%27t_Do_This)

---

## Módulo 15: Constraints (regras de integridade)

**Objetivo:** fazer o banco recusar dados inválidos, em vez de confiar que a aplicação vai sempre acertar.

**Conceitos:**
1. **Constraint**: uma regra que o banco **garante**. Se um comando quebrar a regra, ele falha e nada é gravado.
2. **`NOT NULL`**: a coluna é obrigatória.
3. **`UNIQUE`**: não pode haver dois valores iguais na coluna (vale para e-mail, CPF).
4. **`PRIMARY KEY`**: equivale a `NOT NULL` + `UNIQUE`. Cada tabela tem no máximo uma.
5. **`CHECK (condição)`**: qualquer regra que caiba em uma expressão, como `preco >= 0`.
6. **`FOREIGN KEY` / `REFERENCES`**: o valor precisa existir na tabela referenciada. Isso é a **integridade referencial**: não existe pedido de um cliente que não existe.
7. **`ON DELETE`**: o que acontece com os "filhos" quando o "pai" é apagado:
   - `RESTRICT` / `NO ACTION` (padrão): impede apagar o pai se ele tiver filhos.
   - `CASCADE`: apaga os filhos junto.
   - `SET NULL`: deixa a chave estrangeira dos filhos como `NULL`.
8. **Nomear constraints** (`CONSTRAINT nome CHECK (...)`) deixa as mensagens de erro mais claras.

**Exemplo:**

```sql
CREATE SCHEMA IF NOT EXISTS estudos;

CREATE TABLE estudos.cliente (
  id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome   text NOT NULL,
  email  text NOT NULL UNIQUE,
  idade  integer CONSTRAINT cliente_maior_de_idade CHECK (idade >= 18)
);

CREATE TABLE estudos.pedido (
  id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id  integer NOT NULL REFERENCES estudos.cliente (id) ON DELETE RESTRICT,
  total       numeric(10, 2) NOT NULL CHECK (total >= 0),
  status      text NOT NULL DEFAULT 'pendente'
              CHECK (status IN ('pendente', 'pago', 'cancelado'))
);

INSERT INTO estudos.cliente (nome, email, idade) VALUES ('Ana', 'ana@email.com', 30);
INSERT INTO estudos.pedido (cliente_id, total) VALUES (1, 99.90);

/* Cada linha abaixo deve FALHAR. Rode uma por vez e leia o erro. */
INSERT INTO estudos.cliente (nome, email, idade) VALUES ('Outra Ana', 'ana@email.com', 25);
INSERT INTO estudos.cliente (nome, email, idade) VALUES ('Beto', 'beto@email.com', 15);
INSERT INTO estudos.pedido (cliente_id, total) VALUES (999, 10);
INSERT INTO estudos.pedido (cliente_id, total, status) VALUES (1, 10, 'estornado');
DELETE FROM estudos.cliente WHERE id = 1;
```

**Exercícios:**
1. Rode `\d payment` e `\d rental` no Pagila e liste todas as constraints que você encontrar em cada uma.
2. Crie `estudos.categoria` e `estudos.produto`, em que todo produto pertence a uma categoria. Garanta: nome de categoria único, preço positivo e estoque nunca negativo.
3. Teste cada regra do exercício 2 com um `INSERT` que deveria falhar.
4. Recrie a chave estrangeira de produto com `ON DELETE CASCADE` (você vai precisar apagar e recriar a tabela, ou usar `ALTER TABLE ... DROP CONSTRAINT` e `ADD CONSTRAINT`). Apague uma categoria e veja o que acontece com os produtos.

**Desafio:** crie uma tabela `estudos.reserva(sala text, inicio timestamptz, fim timestamptz)` com uma constraint garantindo que `fim` seja depois de `inicio`, e uma constraint `UNIQUE` composta que impeça duas reservas da mesma sala começando no mesmo horário. Pesquise: essa `UNIQUE` impede reservas que se **sobrepõem** parcialmente? (Dica: pesquise "exclusion constraint", que é um recurso avançado do PostgreSQL; basta entender a ideia.)

**Leitura:** [Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)

---

## Módulo 16: Modelagem e normalização

**Objetivo:** decidir **quais** tabelas criar e como relacioná-las.

**Conceitos:**
1. **Entidade**: uma "coisa" do sistema que vira tabela (cliente, filme, aluguel).
2. **Atributo**: uma característica que vira coluna (nome, preço).
3. **Relacionamento 1:N** (um para muitos): um cliente tem muitos aluguéis. A chave estrangeira fica no lado **N** (`rental.customer_id`).
4. **Relacionamento N:N** (muitos para muitos): um filme tem muitos atores e um ator está em muitos filmes. Precisa de uma **tabela de ligação** (`film_actor`), cuja chave primária costuma ser o par das duas chaves estrangeiras.
5. **Relacionamento 1:1**: raro; geralmente vira colunas na mesma tabela ou uma chave estrangeira com `UNIQUE`.
6. **Normalização**: organizar as tabelas para **cada fato ser guardado uma vez só**. Evita inconsistências (o mesmo cliente com dois e-mails diferentes em linhas diferentes).
7. **1FN (primeira forma normal)**: cada coluna guarda **um valor atômico**. Nada de `"caneta, lápis, borracha"` em uma coluna só.
8. **2FN**: em tabelas com chave composta, cada coluna depende da chave **inteira**, não de só uma parte dela.
9. **3FN**: nenhuma coluna depende de outra coluna que não seja a chave. Exemplo de violação: guardar `cidade` e `estado` no pedido, já que o estado depende da cidade.
10. **Desnormalização**: às vezes repetir um dado de propósito acelera leituras. É uma troca consciente, não um descuido.

**Exemplo (modelo ruim e modelo bom):**

```sql
/* Ruim: uma "planilha" que viola as formas normais */
CREATE TABLE estudos.pedido_planilha (
  pedido_id      integer,
  cliente_nome   text,
  cliente_email  text,
  produtos       text,      /* 'Caneta, Caderno' viola a 1FN */
  cidade         text,
  estado         text       /* depende da cidade: viola a 3FN */
);

/* Melhor: cada fato em seu lugar */
CREATE TABLE estudos.m_cliente (
  id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome   text NOT NULL,
  email  text NOT NULL UNIQUE
);

CREATE TABLE estudos.m_produto (
  id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome   text NOT NULL,
  preco  numeric(10, 2) NOT NULL CHECK (preco >= 0)
);

CREATE TABLE estudos.m_pedido (
  id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id  integer NOT NULL REFERENCES estudos.m_cliente (id),
  feito_em    timestamptz NOT NULL DEFAULT now()
);

/* N:N entre pedido e produto, com a quantidade e o preço da época */
CREATE TABLE estudos.m_pedido_item (
  pedido_id       integer NOT NULL REFERENCES estudos.m_pedido (id) ON DELETE CASCADE,
  produto_id      integer NOT NULL REFERENCES estudos.m_produto (id),
  quantidade      integer NOT NULL CHECK (quantidade > 0),
  preco_unitario  numeric(10, 2) NOT NULL,
  PRIMARY KEY (pedido_id, produto_id)
);
```

Repare no `preco_unitario` em `m_pedido_item`: ele parece repetir o preço do produto, mas não repete. Ele guarda o preço **no momento da compra**, que é outro fato. Se o produto mudar de preço amanhã, o pedido antigo não pode mudar.

**Exercícios:**
1. Desenhe (no papel ou em texto) as tabelas do Pagila que formam relacionamentos N:N. Quais são as tabelas de ligação?
2. Identifique no Pagila um relacionamento 1:N e diga em qual tabela fica a chave estrangeira.
3. Modele uma **escola**: alunos, professores, disciplinas, turmas e matrículas (um aluno se matricula em várias turmas). Escreva os `CREATE TABLE` com todas as constraints.
4. A tabela `estudos.pedido_planilha` do exemplo viola quais formas normais e por quê? Explique cada violação com suas palavras.

**Desafio:** você recebeu esta planilha de uma clínica. Normalize até a 3FN e escreva os `CREATE TABLE`:

| consulta | data | paciente | cpf_paciente | medico | especialidade | crm | procedimentos |
|----------|------|----------|--------------|--------|---------------|-----|---------------|
| 1 | 2026-03-01 | Ana | 111 | Dr. Rui | Cardiologia | 123 | ECG, Consulta |
| 2 | 2026-03-02 | Ana | 111 | Dra. Lia | Dermatologia | 456 | Consulta |
| 3 | 2026-03-02 | Caio | 222 | Dr. Rui | Cardiologia | 123 | Consulta |

**Leitura:** [Microsoft Learn: noções básicas de normalização](https://learn.microsoft.com/pt-br/office/troubleshoot/access/database-normalization-description), [Tutorial PostgreSQL: foreign keys](https://www.postgresql.org/docs/current/tutorial-fk.html)

---

## Módulo 17: INSERT, UPDATE e DELETE

**Objetivo:** criar, alterar e apagar dados com segurança.

**Conceitos:**
1. **DML (Data Manipulation Language)**: `INSERT`, `UPDATE`, `DELETE` (e o `SELECT`).
2. **`INSERT` com várias linhas**: `VALUES (...), (...), (...)`.
3. **`INSERT ... SELECT`**: insere o resultado de uma consulta.
4. **`RETURNING`**: devolve as linhas afetadas, como um `SELECT`. Muito usado para pegar o id gerado. É do PostgreSQL.
5. **`UPDATE tabela SET coluna = valor WHERE ...`**: altera linhas. **Sem `WHERE`, altera a tabela inteira.**
6. **`DELETE FROM tabela WHERE ...`**: apaga linhas. **Sem `WHERE`, apaga tudo.**
7. **Hábito de segurança**: antes de um `UPDATE` ou `DELETE`, rode um `SELECT` com o **mesmo `WHERE`** e confira as linhas. Melhor ainda: faça dentro de uma transação (módulo 18).
8. **`UPDATE ... FROM`**: atualiza usando dados de outra tabela.
9. **Upsert com `ON CONFLICT`**: "insira, e se já existir, faça outra coisa". `DO NOTHING` ignora; `DO UPDATE SET ...` atualiza. `EXCLUDED` representa a linha que você tentou inserir.
10. **`TRUNCATE`**: esvazia a tabela inteira de uma vez. Mais rápido que `DELETE` sem `WHERE`, mas não aceita filtro.

**Exemplo:**

```sql
CREATE SCHEMA IF NOT EXISTS estudos;

CREATE TABLE estudos.contato (
  id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome    text NOT NULL,
  email   text NOT NULL UNIQUE,
  pontos  integer NOT NULL DEFAULT 0
);

INSERT INTO estudos.contato (nome, email)
VALUES ('Ana', 'ana@email.com'),
       ('Bruno', 'bruno@email.com')
RETURNING id, nome;

/* Copiando dados do Pagila */
INSERT INTO estudos.contato (nome, email)
SELECT INITCAP(first_name), LOWER(email)
FROM customer
WHERE customer_id <= 5;

/* Confira antes de alterar */
SELECT * FROM estudos.contato WHERE email = 'ana@email.com';

UPDATE estudos.contato
SET pontos = pontos + 10
WHERE email = 'ana@email.com'
RETURNING *;

/* Upsert: Ana já existe, então só atualiza */
INSERT INTO estudos.contato (nome, email)
VALUES ('Ana Maria', 'ana@email.com')
ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome
RETURNING *;

DELETE FROM estudos.contato
WHERE email = 'bruno@email.com'
RETURNING *;
```

**Exercícios:**
1. Crie `estudos.filme_favorito(id, film_id, titulo, nota)` e preencha com os 10 filmes mais longos do Pagila usando `INSERT ... SELECT`, com `nota` começando em `NULL`.
2. Dê nota `5` para os filmes de classificação `PG` e nota `3` para os demais, usando `UPDATE` com `CASE` (ou dois `UPDATE`s; tente os dois jeitos).
3. Faça um upsert que, ao inserir um filme que já existe na tabela, apenas atualize a nota.
4. Apague os favoritos com nota menor que 4, usando `RETURNING` para ver o que foi apagado.

**Desafio:** crie `estudos.preco_filme` como cópia de `film_id`, `title` e `rental_rate` do Pagila. Depois, com `UPDATE ... FROM`, aumente em 10% o preço dos 50 filmes **mais alugados** (a contagem vem de `rental` e `inventory`).

**Leitura:** [Tutorial: inserting data](https://www.postgresql.org/docs/current/tutorial-populate.html), [INSERT (ON CONFLICT)](https://www.postgresql.org/docs/current/sql-insert.html), [UPDATE](https://www.postgresql.org/docs/current/sql-update.html), [Returning data](https://www.postgresql.org/docs/current/dml-returning.html)

---

## Módulo 18: Transações e ACID

**Objetivo:** garantir que um conjunto de operações aconteça **por inteiro ou não aconteça**.

**Conceitos:**
1. **Transação**: um grupo de comandos tratado como uma unidade.
2. **`BEGIN`** abre, **`COMMIT`** confirma e **`ROLLBACK`** desfaz tudo desde o `BEGIN`.
3. **Autocommit**: sem `BEGIN`, o `psql` trata **cada comando** como uma transação que já é confirmada sozinha.
4. **ACID**, as quatro garantias:
   - **Atomicidade**: tudo ou nada.
   - **Consistência**: a transação leva o banco de um estado válido a outro válido (as constraints continuam valendo).
   - **Isolamento**: transações simultâneas não enxergam o trabalho pela metade uma da outra.
   - **Durabilidade**: depois do `COMMIT`, o dado sobrevive mesmo se o servidor cair.
5. **Erro dentro da transação**: no PostgreSQL, depois de um erro, a transação fica "abortada" e recusa novos comandos até você dar `ROLLBACK`.
6. **`SAVEPOINT`**: um ponto intermediário para desfazer só parte da transação.
7. **Nível de isolamento padrão (Read Committed)**: cada comando enxerga só o que já foi confirmado por outras transações.
8. **Bloqueio (lock)**: se duas transações tentam alterar **a mesma linha**, a segunda espera a primeira terminar.

**Exemplo:**

```sql
CREATE SCHEMA IF NOT EXISTS estudos;

CREATE TABLE estudos.conta (
  id     integer PRIMARY KEY,
  dono   text NOT NULL,
  saldo  numeric(10, 2) NOT NULL CHECK (saldo >= 0)
);
INSERT INTO estudos.conta VALUES (1, 'Ana', 500), (2, 'Bruno', 100);

/* Transferência que dá certo */
BEGIN;
UPDATE estudos.conta SET saldo = saldo - 200 WHERE id = 1;
UPDATE estudos.conta SET saldo = saldo + 200 WHERE id = 2;
COMMIT;

/* Transferência desistida */
BEGIN;
UPDATE estudos.conta SET saldo = saldo - 50 WHERE id = 1;
ROLLBACK;

SELECT * FROM estudos.conta ORDER BY id;
```

Agora tente uma transferência maior que o saldo: o `CHECK (saldo >= 0)` falha no meio, a transação fica abortada e você precisa dar `ROLLBACK`. O dinheiro não some nem aparece do nada.

```sql
BEGIN;
UPDATE estudos.conta SET saldo = saldo + 1000 WHERE id = 2;
UPDATE estudos.conta SET saldo = saldo - 1000 WHERE id = 1;
SELECT * FROM estudos.conta;
ROLLBACK;
```

**Exercícios:**
1. Faça uma transferência de 100 da conta 2 para a 1 dentro de uma transação e confirme.
2. Abra uma transação, faça um `DELETE FROM estudos.conta;` (sem `WHERE`!), consulte a tabela, e então dê `ROLLBACK`. Consulte de novo. Esse é o "cinto de segurança" do módulo 17.
3. Use `SAVEPOINT`: dentro de uma transação, faça duas alterações, crie um savepoint, faça uma terceira, volte ao savepoint (`ROLLBACK TO SAVEPOINT nome`) e confirme. Quais alterações ficaram?
4. **Com dois terminais** (dois `psql` abertos ao mesmo tempo): no terminal A, dê `BEGIN` e altere o saldo da conta 1, **sem** confirmar. No terminal B, consulte a conta 1. Qual saldo aparece? Depois confirme no A e consulte de novo no B.

**Desafio:** repita o exercício 4, mas no terminal B tente fazer um `UPDATE` **na mesma conta** enquanto o A não confirmou. O que acontece com o terminal B? E quando o A dá `COMMIT`? Escreva com suas palavras o que é um lock.

**Leitura:** [Tutorial: transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html), [Transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html)

---

## Questões de entrevista da Fase 4

1. Qual é a diferença entre `DELETE`, `TRUNCATE` e `DROP TABLE`?
2. Qual é a diferença entre chave primária e chave estrangeira? E entre `PRIMARY KEY` e `UNIQUE`?
3. Explique cada letra do ACID com um exemplo de banco de dados bancário.
4. Que tipo de dado você usaria para guardar valores em dinheiro? Por que não `float`?
5. Como você modelaria a relação entre alunos e cursos, sabendo que um aluno faz vários cursos e um curso tem vários alunos?
6. O que é normalização? Cite um caso em que você desnormalizaria de propósito.
7. O que acontece com os pedidos de um cliente quando ele é apagado? Que opções o banco oferece?
8. Você precisa rodar um `UPDATE` em produção. Que cuidados você toma antes?

---

# FASE 5: ORGANIZAÇÃO E PERFORMANCE

## Módulo 19: Views

**Objetivo:** dar nome a consultas que você usa sempre.

**Conceitos:**
1. **View**: uma consulta salva com nome, que pode ser consultada como se fosse uma tabela. Ela **não guarda dados**: cada vez que você consulta, ela roda a consulta original.
2. **Para que serve**: esconder complexidade (um JOIN de 5 tabelas vira um nome simples), padronizar regras de negócio e limitar quais colunas cada usuário vê.
3. **`CREATE OR REPLACE VIEW`**: cria ou atualiza.
4. **Materialized view**: uma view que **guarda o resultado**. É rápida de ler, mas fica desatualizada até você rodar `REFRESH MATERIALIZED VIEW`.
5. **Quando usar cada uma**: view comum para dados que precisam estar sempre atuais; materializada para relatórios pesados que podem ter um pequeno atraso.

**Exemplo:**

```sql
/* O Pagila já vem com views. Veja a definição de uma: */
/* \d+ sales_by_film_category */
SELECT * FROM sales_by_film_category LIMIT 5;

CREATE SCHEMA IF NOT EXISTS estudos;

CREATE OR REPLACE VIEW estudos.faturamento_mensal AS
SELECT DATE_TRUNC('month', payment_date)::date AS mes,
       COUNT(*) AS pagamentos,
       SUM(amount) AS faturamento
FROM payment
GROUP BY DATE_TRUNC('month', payment_date);

SELECT * FROM estudos.faturamento_mensal
WHERE mes >= '2025-01-01'
ORDER BY mes;

CREATE MATERIALIZED VIEW estudos.ranking_clientes AS
SELECT customer_id, SUM(amount) AS total
FROM payment
GROUP BY customer_id;

REFRESH MATERIALIZED VIEW estudos.ranking_clientes;
```

**Exercícios:**
1. Rode `\dv` e escolha duas views do Pagila. Use `\d+ nome_da_view` para ler a definição e explique em uma frase o que cada uma faz.
2. Crie a view `estudos.cliente_completo` com nome completo, e-mail, cidade e país de cada cliente.
3. Crie uma view com os aluguéis em aberto há mais de 30 dias (considere a data de referência `'2026-07-31'`), mostrando cliente, filme e dias de atraso.
4. Use `\timing` para comparar o tempo de consultar uma view comum e uma materializada com o mesmo conteúdo pesado (por exemplo, faturamento por categoria).

**Desafio:** crie a materialized view `estudos.ranking_clientes`, depois insira um pagamento novo para um cliente (`INSERT INTO payment ...` com uma data entre 2022 e julho de 2026). Consulte a view: o valor mudou? Rode o `REFRESH` e consulte de novo. Explique o comportamento.

**Leitura:** [Tutorial: views](https://www.postgresql.org/docs/current/tutorial-views.html), [Materialized views](https://www.postgresql.org/docs/current/rules-materializedviews.html)

---

## Módulo 20: Índices e EXPLAIN

**Objetivo:** entender por que algumas consultas são lentas e como o índice ajuda.

**Conceitos:**
1. **Varredura sequencial (Seq Scan)**: sem índice, o banco lê a tabela **inteira** para achar as linhas. É como procurar uma palavra em um livro lendo todas as páginas.
2. **Índice**: uma estrutura extra, ordenada, que aponta para onde estão as linhas. É o "índice remissivo" no fim do livro.
3. **B-tree**: o tipo de índice padrão. Serve para `=`, `<`, `>`, `BETWEEN`, `ORDER BY` e `LIKE 'abc%'` (com prefixo fixo, sob certas condições).
4. **Índice não é de graça**: ocupa espaço e deixa `INSERT`, `UPDATE` e `DELETE` mais lentos, porque o índice também precisa ser atualizado.
5. **A chave primária e o `UNIQUE` criam índices automaticamente.** As chaves estrangeiras **não** (o Pagila cria alguns manualmente; veja os `idx_fk_` no `\d rental`).
6. **`EXPLAIN`**: mostra o **plano** que o banco pretende usar, sem executar.
7. **`EXPLAIN ANALYZE`**: executa de verdade e mostra o tempo real de cada etapa. Cuidado: com `UPDATE` e `DELETE`, ele **altera os dados** (use dentro de `BEGIN ... ROLLBACK`).
8. **O planejador decide**: mesmo existindo índice, o banco pode preferir o Seq Scan se a consulta for trazer boa parte da tabela.
9. **`ANALYZE tabela`**: atualiza as estatísticas que o planejador usa para decidir.
10. **Índice composto**: `(a, b)` ajuda filtros por `a` e por `a` + `b`, mas não ajuda um filtro só por `b`. A ordem das colunas importa.
11. **Funções na coluna desligam o índice comum**: `WHERE LOWER(email) = '...'` não usa um índice em `email`. A solução é um índice na expressão: `CREATE INDEX ... (LOWER(email))`.

**Exemplo:**

```sql
CREATE SCHEMA IF NOT EXISTS estudos;

/* Uma cópia de rental SEM nenhum índice */
CREATE TABLE estudos.aluguel AS SELECT * FROM rental;
ANALYZE estudos.aluguel;

EXPLAIN ANALYZE
SELECT * FROM estudos.aluguel WHERE customer_id = 100;

CREATE INDEX aluguel_customer_id_idx ON estudos.aluguel (customer_id);

EXPLAIN ANALYZE
SELECT * FROM estudos.aluguel WHERE customer_id = 100;
```

No primeiro plano você deve ver `Seq Scan`. No segundo, `Bitmap Index Scan` ou `Index Scan` usando o índice criado, com tempo menor. Compare os valores de `Execution Time`.

**Exercícios:**
1. Rode `\d rental` e liste os índices que o Pagila já criou. Para cada um, diga que tipo de consulta ele ajuda.
2. Na tabela `estudos.aluguel`, rode `EXPLAIN` para `WHERE customer_id = 100 AND inventory_id = 5`. Depois crie um índice composto `(customer_id, inventory_id)` e compare. Teste também um filtro só por `inventory_id` e observe se o índice composto é usado.
3. Rode `EXPLAIN` para `SELECT * FROM customer WHERE LOWER(email) = 'mary.smith@sakilacustomer.org';` em uma cópia de `customer` com índice em `email`. O índice é usado? Crie um índice na expressão `LOWER(email)` e compare.
4. Rode `EXPLAIN` em `SELECT * FROM estudos.aluguel WHERE customer_id > 10;` (com o índice criado). O banco usou o índice? Por que não?

**Desafio:** escolha a consulta mais pesada que você escreveu nas fases 2 e 3 (por exemplo, o faturamento por categoria). Rode `EXPLAIN ANALYZE`, identifique a etapa mais cara e explique, com suas palavras, o que o banco está fazendo nela. Proponha um índice e verifique se ele ajudou.

**Leitura:** [Indexes](https://www.postgresql.org/docs/current/indexes.html), [Using EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html), [Indexes on expressions](https://www.postgresql.org/docs/current/indexes-expressional.html), [Multicolumn indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html)

---

## Questões de entrevista da Fase 5

1. O que é um índice e como ele acelera uma consulta? Por que não criar índice em todas as colunas?
2. Uma consulta ficou lenta em produção. Quais são seus primeiros passos para investigar?
3. Qual é a diferença entre view e materialized view?
4. Você tem um índice composto em `(sobrenome, nome)`. Ele ajuda em `WHERE nome = 'Ana'`? E em `WHERE sobrenome = 'Silva'`?
5. Por que `WHERE LOWER(email) = 'x'` pode não usar o índice da coluna `email`?
6. Qual é a diferença entre `EXPLAIN` e `EXPLAIN ANALYZE`? Que cuidado tomar com o segundo?

---

# FASE 6: PROJETO FINAL E EXTRA

## Módulo 21: Projeto final, o banco do Gerenciador de Tarefas

**Objetivo:** modelar, criar, popular e consultar um banco do zero, juntando tudo o que você estudou. O domínio é o mesmo do projeto final do roteiro de TypeScript, para que o módulo 22 conecte os dois.

**Requisitos:**

1. **Schema próprio**: tudo dentro do schema `tarefas`.
2. **Tabelas mínimas**:
   - `usuario`: nome, e-mail único, criado em.
   - `projeto`: nome, dono (um usuário).
   - `tarefa`: título, descrição opcional, projeto, responsável (usuário, opcional), prioridade (`baixa`, `media`, `alta`), status (`pendente`, `em_andamento`, `concluida`), criada em, prazo opcional, concluída em (opcional).
   - `etiqueta` e uma tabela de ligação N:N entre tarefa e etiqueta.
   - `comentario`: texto, autor, tarefa, criado em.
3. **Constraints**: chaves primárias e estrangeiras, `CHECK` nas listas de opções, e uma regra garantindo que `concluida_em` só pode ser preenchida quando o status for `concluida` (e vice-versa).
4. **Dados**: pelo menos 5 usuários, 3 projetos, 40 tarefas, 6 etiquetas e 30 comentários. Use `INSERT ... SELECT` com `generate_series` e `random()` para gerar dados em volume.
5. **Consultas de relatório** (cada uma em um arquivo):
   1. Tarefas atrasadas (prazo vencido e não concluídas), com responsável e dias de atraso.
   2. Quantidade de tarefas por status em cada projeto.
   3. Usuários sem nenhuma tarefa atribuída.
   4. As 3 etiquetas mais usadas.
   5. Tempo médio de conclusão por prioridade.
   6. Ranking de usuários por tarefas concluídas, com `DENSE_RANK`.
   7. Tarefas concluídas por semana, com o total acumulado.
   8. Para cada tarefa, o último comentário feito nela.
6. **Uma view** com o "painel" de cada projeto (total, concluídas, percentual concluído, atrasadas).
7. **Uma transação** que conclui uma tarefa e registra um comentário automático ao mesmo tempo.
8. **Um índice justificado**: escolha uma das consultas, mostre o `EXPLAIN ANALYZE` antes e depois do índice.
9. **Organização em arquivos**, executáveis em ordem:

```
projeto-final/
  01-schema.sql      DROP SCHEMA IF EXISTS tarefas CASCADE; CREATE SCHEMA tarefas; e as tabelas
  02-dados.sql       inserts
  03-views.sql
  04-indices.sql
  consultas/
    01-atrasadas.sql
    ...
```

Rodar `01-schema.sql` no início deve deixar tudo limpo, para você poder recriar o banco do projeto quantas vezes quiser.

**Conceitos aplicados por módulo:**

| Parte do projeto | Módulos |
|------------------|---------|
| Tabelas, tipos e constraints | 14, 15 |
| Modelagem e N:N | 16 |
| Geração de dados | 11, 17 |
| Relatórios | 6 a 13 |
| View | 19 |
| Transação | 18 |
| Índice | 20 |

**Extras opcionais:** histórico de mudanças de status em uma tabela separada; subtarefas (uma tarefa que aponta para outra tarefa-mãe) consultadas com `WITH RECURSIVE`.

---

## Módulo 22 (extra): Usando o PostgreSQL a partir do TypeScript

**Objetivo:** fazer a aplicação do roteiro de TypeScript ler e gravar no banco do projeto final, em vez de usar um arquivo JSON.

**Pré-requisito:** ter concluído o módulo 21 deste roteiro e os módulos 12 (módulos), 13 (erros) e 20 (assincronismo) do roteiro de TypeScript.

**Conceitos:**
1. **Driver**: a biblioteca que sabe "conversar" com o PostgreSQL. No Node, a mais usada é a `pg` (projeto node-postgres).
2. **Connection string**: o endereço do banco em uma linha: `postgres://usuario:senha@host:porta/database`.
3. **Pool de conexões**: abrir uma conexão é caro. O `Pool` mantém algumas abertas e reaproveita.
4. **Consulta parametrizada**: os valores vão separados do SQL, com marcadores `$1`, `$2`. O banco recebe o texto e os valores em partes diferentes.
5. **SQL injection**: o ataque que acontece quando você **concatena** texto do usuário no SQL. Se alguém digitar `' OR '1'='1` em um campo, uma consulta montada com `+` muda de sentido. Consultas parametrizadas eliminam esse risco. **Nunca monte SQL concatenando valores vindos de fora.**
6. **Tipos que voltam como texto**: por padrão, a `pg` devolve `numeric` e `bigint` (incluindo o resultado de `COUNT(*)`) como **string**, para não perder precisão no `number` do JavaScript. Você converte quando fizer sentido.
7. **Tipando o resultado**: `pool.query<Tipo>(...)` diz ao TypeScript o formato de cada linha. O TypeScript **confia** nisso, não verifica.
8. **Transação no código**: pegue um cliente do pool (`pool.connect()`), rode `BEGIN`, os comandos e `COMMIT`, e use `ROLLBACK` no `catch`. Sempre libere o cliente no `finally`.

**Passo a passo** (na pasta do projeto TypeScript):

```bash
npm install pg
npm install -D @types/pg
```

**Exemplo** (`banco.ts`), usando o Pagila para testar:

```ts
import pg from "pg";

const pool = new pg.Pool({
  connectionString: "postgres://postgres:123456@localhost:5432/pagila",
});

interface Filme {
  title: string;
  rental_rate: string; // numeric chega como string
}

async function filmesPorClassificacao(rating: string): Promise<Filme[]> {
  const resultado = await pool.query<Filme>(
    "SELECT title, rental_rate FROM film WHERE rating = $1 ORDER BY title LIMIT 5",
    [rating],
  );
  return resultado.rows;
}

async function contarFilmes(): Promise<number> {
  const resultado = await pool.query<{ total: string }>("SELECT COUNT(*) AS total FROM film");
  return Number(resultado.rows[0].total);
}

try {
  console.log(await contarFilmes());
  for (const f of await filmesPorClassificacao("PG")) {
    console.log(f.title, Number(f.rental_rate).toFixed(2));
  }
} finally {
  await pool.end();
}
```

Execute com `node banco.ts`. O exemplo foi testado com a versão 8.23 da `pg`, em que tanto `import pg from "pg"` (usado acima) quanto `import { Pool } from "pg"` funcionam. Ele também passa no `npm run check` com o `tsconfig.json` do roteiro de TypeScript.

**Exercícios:**
1. Crie uma função `buscarCliente(email: string)` que retorna o cliente ou `undefined`. Teste com um e-mail que existe e com outro que não existe.
2. Crie uma versão **insegura** que monta o SQL concatenando o e-mail, e teste passando `' OR '1'='1` como e-mail. Quantas linhas voltaram? Depois compare com a versão parametrizada. (Faça isso só no seu banco local de estudos.)
3. Crie uma função `transferir(origem, destino, valor)` para a tabela `estudos.conta` do módulo 18, usando transação com `BEGIN`, `COMMIT` e `ROLLBACK`.
4. Adapte o repositório do Gerenciador de Tarefas do roteiro de TypeScript para ler e gravar no schema `tarefas` do módulo 21.

**Desafio:** crie uma função genérica `consultar<T>(sql: string, params: unknown[]): Promise<T[]>` e uma camada que converta automaticamente os campos `numeric` de string para `number` nos lugares em que você sabe que não haverá perda de precisão. Escreva testes com `node:test` (módulo 14 do roteiro de TypeScript).

**Leitura:** [node-postgres: queries](https://node-postgres.com/features/queries), [node-postgres: pooling](https://node-postgres.com/features/pooling), [node-postgres: transactions](https://node-postgres.com/features/transactions), [node-postgres: data types](https://node-postgres.com/features/types), [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)

---

# APÊNDICES

## A. Erros comuns e o que significam

| Mensagem (resumida) | Causa mais comum |
|---------------------|------------------|
| `column "x" does not exist` | Nome errado, ou você usou aspas duplas em um texto (`"PG"` em vez de `'PG'`) |
| `column "x" must appear in the GROUP BY clause` | Coluna no `SELECT` que não está no `GROUP BY` nem dentro de agregação |
| `column reference "x" is ambiguous` | Duas tabelas do JOIN têm essa coluna; use `tabela.x` |
| `syntax error at or near` | Vírgula sobrando ou faltando, palavra-chave fora de ordem |
| `current transaction is aborted` | Houve um erro dentro do `BEGIN`; rode `ROLLBACK` |
| `duplicate key value violates unique constraint` | Valor repetido em coluna `UNIQUE` ou chave primária |
| `violates foreign key constraint` | O valor não existe na tabela referenciada, ou o pai tem filhos |
| `relation "x" does not exist` | Tabela com nome errado ou em outro schema (use `estudos.x`) |
| `permission denied while trying to connect to the Docker daemon` | Faltou o `sudo` antes do `docker` |
| `port is already allocated` (ao subir o compose) | Outro container usa a porta 5432; veja o passo 2 do módulo 0 |

## B. Ordem de escrita e ordem de execução

```
Ordem em que você ESCREVE        Ordem em que o banco PROCESSA
SELECT                           1. FROM e JOINs
FROM                             2. WHERE
JOIN ... ON                      3. GROUP BY
WHERE                            4. HAVING
GROUP BY                         5. Window functions
HAVING                           6. SELECT (expressões e apelidos)
ORDER BY                         7. DISTINCT
LIMIT / OFFSET                   8. ORDER BY
                                 9. LIMIT / OFFSET
```

Essa tabela explica a maioria dos erros "por que não posso usar isso aqui?". Ela é uma ordem **lógica**: o planejador pode executar de outro jeito por baixo, desde que o resultado seja o mesmo.

## C. Checklist de progresso

- [x] Módulo 0: Ambiente
- [ ] Módulo 1: Primeiro SELECT
- [ ] Módulo 2: WHERE
- [ ] Módulo 3: NULL
- [ ] Módulo 4: Ordenação e ordem de execução
- [ ] Módulo 5: Funções e CASE
- [ ] Questões da Fase 1
- [ ] Módulo 6: GROUP BY e HAVING
- [ ] Módulo 7: INNER JOIN
- [ ] Módulo 8: LEFT JOIN e companhia
- [ ] Módulo 9: UNION, INTERSECT, EXCEPT
- [ ] Questões da Fase 2
- [ ] Módulo 10: Subconsultas
- [ ] Módulo 11: CTEs
- [ ] Módulo 12: Window functions (rankings)
- [ ] Módulo 13: Window functions (LAG, LEAD, acumulados)
- [ ] Questões da Fase 3
- [ ] Módulo 14: Tipos e CREATE TABLE
- [ ] Módulo 15: Constraints
- [ ] Módulo 16: Modelagem e normalização
- [ ] Módulo 17: INSERT, UPDATE, DELETE
- [ ] Módulo 18: Transações
- [ ] Questões da Fase 4
- [ ] Módulo 19: Views
- [ ] Módulo 20: Índices e EXPLAIN
- [ ] Questões da Fase 5
- [ ] Módulo 21: Projeto final
- [ ] Módulo 22: TypeScript e PostgreSQL

---

## Fontes

- [Documentação oficial do PostgreSQL](https://www.postgresql.org/docs/current/): base de todos os conceitos e da ordem dos tópicos (o tutorial oficial segue a sequência consultas, joins, agregação, views, chaves estrangeiras, transações e window functions).
- [Tutorial oficial do PostgreSQL](https://www.postgresql.org/docs/current/tutorial.html): estrutura das fases 1 a 3.
- [PostgreSQL Wiki: Don't Do This](https://wiki.postgresql.org/wiki/Don%27t_Do_This): recomendações sobre `NOT IN`, `timestamptz`, `serial`, `varchar(n)` e dinheiro.
- [Pagila no GitHub](https://github.com/devrimgunduz/pagila): banco de exemplo, `docker-compose.yml`, credenciais e requisito de PostgreSQL 18.
- [Imagem oficial do PostgreSQL no Docker Hub](https://hub.docker.com/_/postgres) e [docker-library/postgres#1259](https://github.com/docker-library/postgres/pull/1259): mudança do caminho do volume na versão 18 (o compose do Pagila já está ajustado).
- [Omarchy no GitHub](https://github.com/basecamp/omarchy): pacotes Docker incluídos, instalador "Docker DB" (`bin/omarchy-install-docker-dbs`) e a decisão de não colocar o usuário no grupo `docker` por padrão (`install/config/docker.sh`).
- [node-postgres](https://node-postgres.com/): módulo 22.
- [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection): módulo 22.

> Os exemplos SQL deste roteiro foram executados contra o Pagila carregado em um PostgreSQL 18 antes da entrega. Os números citados (como 51805 aluguéis) são da versão do Pagila disponível em outubro de 2026 e podem mudar levemente em versões futuras.

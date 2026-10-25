# Comandos de uso frequente

Extraído da Fase 0 do `roteiro-sql.md`, com os caminhos deste repositório.

## Comandos do `psql`

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

## Entrar no `psql`

Pelo container (como no roteiro):

```bash
sudo docker exec -it pagila psql -U postgres -d pagila
```

Pelo `psql` do próprio sistema, sem `sudo` (pede a senha do `docker-compose.yml`):

```bash
psql -h localhost -U postgres -d pagila
```

## Rodar um exercício a partir do arquivo

Na raiz do repositório (`~/Projects/learning-postgresql`):

```bash
sudo docker exec -i pagila psql -U postgres -d pagila < modulo-01/ex1.sql
```

Note que aqui é `-i` e não `-it`: o `<` manda o conteúdo do arquivo para dentro do `psql`.

Sem Docker, pelo `psql` do sistema:

```bash
psql -h localhost -U postgres -d pagila -f modulo-01/ex1.sql
```

## Containers no dia a dia

Todos rodados de dentro da pasta `pagila/`:

| Situação | Comando |
|----------|---------|
| Ligar os containers (por exemplo, depois de reiniciar o PC) | `sudo docker compose start` |
| Desligar os containers | `sudo docker compose stop` |
| Ver se estão rodando | `sudo docker compose ps` |
| Ver se o banco aceita conexões (sem `sudo`) | `pg_isready -h localhost -p 5432` |
| **Resetar o banco** (apaga tudo e recarrega o Pagila original) | `sudo docker compose down -v` e depois `sudo docker compose up -d` |

O reset é o "botão de desfazer". Na Fase 4 você vai alterar dados, e se algo der muito errado é só resetar. Atenção: o `-v` apaga o volume com os dados, inclusive tudo o que você criou no schema `estudos`.

De qualquer pasta, para ver todos os containers do sistema (não só os do `pagila/`):

| Situação | Comando |
|----------|---------|
| Ver os containers que estão rodando | `sudo docker ps` |
| Ver todos, inclusive os parados | `sudo docker ps -a` |

A diferença para o `docker compose ps`: o `compose ps` mostra só os containers do `docker-compose.yml` da pasta atual, e o `docker ps` mostra todos os que o Docker conhece. Na coluna `STATUS`, `Up` quer dizer rodando e `Exited` quer dizer parado.

## Fontes

- [Documentação do psql](https://www.postgresql.org/docs/current/app-psql.html)
- [pg_isready](https://www.postgresql.org/docs/current/app-pg-isready.html)
- [docker compose](https://docs.docker.com/reference/cli/docker/compose/)
- [docker ps](https://docs.docker.com/reference/cli/docker/container/ls/)

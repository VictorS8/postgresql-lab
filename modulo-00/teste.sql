-- Exercicio 0.1
-- (81 rows) de tabelas ao rodar o \dt

-- Colunas na tabela film:
-- film_id (primary key), title, description, release_year, language_id, original_language_id,
-- rental_duration, rental_rate (numeric 4,2), length, replacement_cost, rating,
-- last_update, special_features, fulltext, length_hours

-- rental_rate é do tipo numeric(4,2)
-- film_id é Primary Key

-- Exercicio 0.2
SELECT count(*) FROM film;

-- count(*) retorna o número de linhas na tabela film, que é 1000.
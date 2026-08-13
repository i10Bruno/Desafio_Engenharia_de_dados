-- Gera uma dimensão de calendário (com Domingo = 0) e calcula estatísticas de vendas no PDV.
WITH calendario AS (
    SELECT
        d::date AS data,
        EXTRACT(DOW FROM d)::int AS numero_dia_semana,
        CASE EXTRACT(DOW FROM d)::int
            WHEN 0 THEN 'Domingo'
            WHEN 1 THEN 'Segunda-feira'
            WHEN 2 THEN 'Terça-feira'
            WHEN 3 THEN 'Quarta-feira'
            WHEN 4 THEN 'Quinta-feira'
            WHEN 5 THEN 'Sexta-feira'
            WHEN 6 THEN 'Sábado'
        END AS dia_semana
    FROM (
        SELECT generate_series(MIN(placed_at::date), MAX(placed_at::date), INTERVAL '1 day') AS d
        FROM orders
    ) sub
),

vendas_diarias AS (
    SELECT
        placed_at::date AS data,
        SUM(total) AS venda_diaria
    FROM orders
    WHERE channel = 'pos'
    GROUP BY placed_at::date
)

SELECT
    c.numero_dia_semana,
    c.dia_semana,
    COUNT(*) AS dias_no_calendario,
    COUNT(*) FILTER (WHERE v.venda_diaria IS NULL OR v.venda_diaria = 0) AS dias_sem_venda,
    ROUND(AVG(COALESCE(v.venda_diaria, 0)), 2) AS media_vendas_diarias
FROM calendario c
LEFT JOIN vendas_diarias v ON v.data = c.data
GROUP BY c.numero_dia_semana, c.dia_semana
ORDER BY media_vendas_diarias ASC, c.numero_dia_semana ASC;
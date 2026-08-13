-- Identifica os 10 clientes mais fiéis (diversidade >= 13 categorias) ranqueados pelos maiores tickets médios.
WITH categorias_por_cliente AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.category_id) AS diversidade_categorias
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN product_variants pv ON pv.id = oi.product_variant_id
    JOIN products p ON p.id = pv.product_id
    GROUP BY o.customer_id
),

ticket_por_cliente AS (
    SELECT
        customer_id,
        AVG(total) AS ticket_medio
    FROM orders
    GROUP BY customer_id
),

clientes_fieis AS (
    SELECT
        t.customer_id,
        t.ticket_medio,
        c.diversidade_categorias
    FROM ticket_por_cliente t
    JOIN categorias_por_cliente c ON c.customer_id = t.customer_id
    WHERE c.diversidade_categorias >= 13
    ORDER BY
        t.ticket_medio DESC,
        t.customer_id ASC
    LIMIT 10
)

SELECT
    customer_id,
    ROUND(ticket_medio::numeric, 2) AS ticket_medio,
    diversidade_categorias
FROM clientes_fieis
ORDER BY
    ticket_medio DESC,
    customer_id ASC;
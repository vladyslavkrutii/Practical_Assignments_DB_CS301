-- PostgreSQL Optimization Demo
-- Use EXPLAIN or EXPLAIN ANALYZE before each query to compare execution plans.

-- ============================================================
-- 1. Non-optimized query
-- ============================================================
-- Execution Time до оптимізації 427.9 ms
EXPLAIN ANALYZE
SELECT
    (
        SELECT CONCAT(brand, ': ', total_price)
        FROM (
            SELECT brand, SUM(price) AS total_price
            FROM (
                SELECT
                    o.id AS order_id,
                    o.order_date,
                    o.price,
                    c.id AS car_id,
                    c.brand,
                    cl.id AS client_id
                FROM opt_orders AS o
                JOIN opt_cars AS c
                    ON o.car_id = c.id
                JOIN opt_clients AS cl
                    ON o.client_id = cl.id
                WHERE o.order_date > DATE '2023-01-01'
                  AND cl.status = 'active'
            ) AS sub1
            GROUP BY brand
        ) AS sub2
        WHERE total_price = (
            SELECT MIN(total_price)
            FROM (
                SELECT SUM(price) AS total_price
                FROM (
                    SELECT
                        o.id AS order_id,
                        o.order_date,
                        o.price,
                        c.id AS car_id,
                        c.brand,
                        cl.id AS client_id
                    FROM opt_orders AS o
                    JOIN opt_cars AS c
                        ON o.car_id = c.id
                    JOIN opt_clients AS cl
                        ON o.client_id = cl.id
                    WHERE o.order_date > DATE '2023-01-01'
                      AND cl.status = 'active'
                ) AS sub3
                GROUP BY brand
            ) AS sub4
        )
        LIMIT 1
    ) AS min_cnt,

    (
        SELECT CONCAT(brand, ': ', total_price)
        FROM (
            SELECT brand, SUM(price) AS total_price
            FROM (
                SELECT
                    o.id AS order_id,
                    o.order_date,
                    o.price,
                    c.id AS car_id,
                    c.brand,
                    cl.id AS client_id
                FROM opt_orders AS o
                JOIN opt_cars AS c
                    ON o.car_id = c.id
                JOIN opt_clients AS cl
                    ON o.client_id = cl.id
                WHERE o.order_date > DATE '2023-01-01'
                  AND cl.status = 'active'
            ) AS sub1
            GROUP BY brand
        ) AS sub2
        WHERE total_price = (
            SELECT MAX(total_price)
            FROM (
                SELECT SUM(price) AS total_price
                FROM (
                    SELECT
                        o.id AS order_id,
                        o.order_date,
                        o.price,
                        c.id AS car_id,
                        c.brand,
                        cl.id AS client_id
                    FROM opt_orders AS o
                    JOIN opt_cars AS c
                        ON o.car_id = c.id
                    JOIN opt_clients AS cl
                        ON o.client_id = cl.id
                    WHERE o.order_date > DATE '2023-01-01'
                      AND cl.status = 'active'
                ) AS sub3
                GROUP BY brand
            ) AS sub4
        )
        LIMIT 1
    ) AS max_cnt;


-- ============================================================
-- 2. Indexes for optimization
-- ============================================================
-- створення індексів щоб уникать повного перебору данних
CREATE INDEX IF NOT EXISTS idx_opt_orders_order_date
    ON opt_orders(order_date);

CREATE INDEX IF NOT EXISTS idx_opt_orders_car_id
    ON opt_orders(car_id);

CREATE INDEX IF NOT EXISTS idx_opt_orders_client_id
    ON opt_orders(client_id);

CREATE INDEX IF NOT EXISTS idx_opt_clients_status
    ON opt_clients(status);


-- ============================================================
-- 3. Optimized query
-- ============================================================
-- запит до таблиці замовлень один раз у CTE `filtered_orders`
-- фільтрація брендів за прибутком робимо за один прохід через ROW_NUMBER()
-- індекси використовуються
-- Execution Time після оптимізації 180.6 ms


EXPLAIN ANALYZE
WITH filtered_orders AS (
    SELECT
        o.id AS order_id,
        o.order_date,
        o.price,
        c.id AS car_id,
        c.brand,
        cl.id AS client_id
    FROM opt_orders AS o
    JOIN opt_cars AS c
        ON o.car_id = c.id
    JOIN opt_clients AS cl
        ON o.client_id = cl.id
    WHERE o.order_date > DATE '2023-01-01'
      AND cl.status = 'active'
),
cnt_brands AS (
    SELECT
        brand,
        SUM(price) AS total_price
    FROM filtered_orders
    GROUP BY brand
),
ranked_brands AS (
    SELECT
        brand,
        total_price,
        ROW_NUMBER() OVER (ORDER BY total_price ASC, brand ASC) AS min_rn,
        ROW_NUMBER() OVER (ORDER BY total_price DESC, brand ASC) AS max_rn
    FROM cnt_brands
)
SELECT
    MAX(CONCAT(brand, ': ', total_price)) FILTER (WHERE min_rn = 1) AS min_cnt,
    MAX(CONCAT(brand, ': ', total_price)) FILTER (WHERE max_rn = 1) AS max_cnt
FROM ranked_brands;
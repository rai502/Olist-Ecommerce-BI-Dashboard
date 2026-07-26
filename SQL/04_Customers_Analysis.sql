/*
===========================================================
Project : Olist Brazilian E-commerce Analysis
Section : Customer Analysis
Database: PostgreSQL
===========================================================
*/

-- ===========================================================
-- Q1. How many unique customers placed at least one delivered order?
-- Purpose: Measure the total number of unique customers who completed a delivered purchase.
-- ===========================================================

SELECT
    COUNT(DISTINCT c.customer_unique_id) AS total_unique_customers
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered';

-- ===========================================================
-- Q2. Which 10 states have the highest number of unique customers who placed delivered orders?
-- Purpose: Identify the states with the largest active customer base.
-- ===========================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY unique_customers DESC
LIMIT 10;

-- ===========================================================
-- Q3. Which 10 cities have the highest number of unique customers who placed delivered orders?
-- Purpose: Identify the cities with the highest number of active customers.
-- ===========================================================

SELECT
    c.customer_city,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city
ORDER BY unique_customers DESC
LIMIT 10;

-- ===========================================================
-- Q4. Which 10 customers generated the highest revenue from delivered orders?
-- Purpose: Identify the highest-value customers based on total spending.
-- ===========================================================

SELECT
    c.customer_unique_id,
    SUM(oi.price) AS total_revenue
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC
LIMIT 10;

-- ===========================================================
-- Q5. What is the average number of delivered orders placed per customer?
-- Purpose: Measure the average purchase frequency per customer.
-- ===========================================================

WITH customers_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    AVG(total_orders) AS avg_orders_per_customer
FROM customers_orders;

-- ===========================================================
-- Q6. How many customers are returning customers?
-- Purpose: Count customers who placed more than one delivered order.
-- ===========================================================

WITH customers_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
    HAVING COUNT(o.order_id) > 1
)

SELECT
    COUNT(*) AS returning_customers
FROM customers_orders;

-- ===========================================================
-- Q7. What percentage of customers are returning customers?
-- Purpose: Calculate the repeat purchase rate among delivered-order customers.
-- ===========================================================

WITH returning_customers AS (
    SELECT
        COUNT(*) AS returning_customers
    FROM (
        SELECT
            c.customer_unique_id
        FROM customers c
        JOIN orders o
            ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
        HAVING COUNT(o.order_id) > 1
    ) t
),
total_customers AS (
    SELECT
        COUNT(DISTINCT c.customer_unique_id) AS total_customers
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)

SELECT
    rc.returning_customers,
    tc.total_customers,
    ROUND(
        (
            rc.returning_customers * 100.0 /
            tc.total_customers
        )::numeric,
        2
    ) AS repeat_purchase_rate
FROM returning_customers rc
CROSS JOIN total_customers tc;

-- ===========================================================
-- Q8. Which customers spent more than the average customer spend?
-- Purpose: Identify customers whose total spending exceeds the average customer spending.
-- ===========================================================

WITH customers_spend AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spending
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    total_spending
FROM customers_spend
WHERE total_spending > (
    SELECT AVG(total_spending)
    FROM customers_spend
)
ORDER BY total_spending DESC;

-- ===========================================================
-- Q9. Which customers have placed more than one delivered order?
-- Purpose: Identify repeat customers based on delivered orders.
-- ===========================================================

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;
